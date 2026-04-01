from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from appointments.models import Appointment
from .models import PaymentOrder
from .serializers import CreateOrderSerializer, VerifyPaymentSerializer, PaymentOrderSerializer
from .services import create_razorpay_order, verify_razorpay_payment


class CreatePaymentOrderView(APIView):
    """
    POST /api/payments/create-order/
    Body: { appointment_id, amount }

    Creates a Razorpay order and returns the order_id to Flutter.
    Flutter uses this order_id to open the Razorpay checkout sheet.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = CreateOrderSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        appointment_id = serializer.validated_data['appointment_id']

        # Security: make sure this appointment belongs to this patient
        try:
            appointment = Appointment.objects.get(
                id=appointment_id,
                patient__user=request.user,
            )
        except Appointment.DoesNotExist:
            return Response(
                {'error': 'Appointment not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Prevent double payment
        if hasattr(appointment, 'payment_order') and \
                appointment.payment_order.status == 'paid':
            return Response(
                {'error': 'This appointment has already been paid for.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        amount = serializer.validated_data.get('amount')
        try:
            payment_order = create_razorpay_order(appointment, request.user, amount=amount)
        except Exception as e:
            return Response(
                {'error': f'Could not create payment order: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        return Response({
            'order_id':       payment_order.gateway_order_id,
            'amount':         float(payment_order.amount),
            'currency':       payment_order.currency,
            'appointment_id': appointment.id,
        }, status=status.HTTP_201_CREATED)


class VerifyPaymentView(APIView):
    """
    POST /api/payments/verify/
    Body: { razorpay_order_id, razorpay_payment_id, razorpay_signature }

    Verifies the Razorpay signature using HMAC-SHA256.
    If valid, marks the appointment as confirmed.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = VerifyPaymentSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        rz_order_id   = serializer.validated_data['razorpay_order_id']
        rz_payment_id = serializer.validated_data['razorpay_payment_id']
        rz_signature  = serializer.validated_data['razorpay_signature']

        try:
            payment_order = PaymentOrder.objects.get(gateway_order_id=rz_order_id)
        except PaymentOrder.DoesNotExist:
            return Response(
                {'error': 'Payment order not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Security: make sure this patient owns this payment
        if payment_order.patient != request.user:
            return Response(
                {'error': 'Unauthorized.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        is_valid = verify_razorpay_payment(
            payment_order=payment_order,
            razorpay_payment_id=rz_payment_id,
            razorpay_signature=rz_signature,
        )

        if is_valid:
            return Response({
                'success':        True,
                'message':        'Payment verified. Appointment confirmed.',
                'appointment_id': payment_order.appointment.id,
            })
        else:
            return Response(
                {'success': False, 'error': 'Invalid payment signature.'},
                status=status.HTTP_400_BAD_REQUEST,
            )


class PaymentHistoryView(APIView):
    """
    GET /api/payments/history/
    Returns the logged-in patient's payment history.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        orders = PaymentOrder.objects.filter(
            patient=request.user
        ).order_by('-created_at')
        return Response(PaymentOrderSerializer(orders, many=True).data)
