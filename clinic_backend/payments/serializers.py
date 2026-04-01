from rest_framework import serializers
from .models import PaymentOrder, PaymentTransaction


class CreateOrderSerializer(serializers.Serializer):
    appointment_id = serializers.IntegerField()
    amount         = serializers.DecimalField(max_digits=10, decimal_places=2)


class VerifyPaymentSerializer(serializers.Serializer):
    razorpay_order_id   = serializers.CharField()
    razorpay_payment_id = serializers.CharField()
    razorpay_signature  = serializers.CharField()


class PaymentOrderSerializer(serializers.ModelSerializer):
    class Meta:
        model  = PaymentOrder
        fields = [
            'id', 'appointment', 'amount', 'currency',
            'gateway_order_id', 'status', 'paid_at', 'created_at',
        ]
