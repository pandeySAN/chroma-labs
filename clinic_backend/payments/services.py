"""
All Razorpay logic lives here — never in views.py.
Keys are read from Django settings which reads from .env.
"""
import hmac
import hashlib

import razorpay
from django.conf import settings
from django.utils import timezone

from .models import PaymentOrder, PaymentTransaction
from appointments.models import Appointment


# Razorpay client — initialised once at import time
_client = razorpay.Client(
    auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
)


def create_razorpay_order(appointment: Appointment, patient, amount=None) -> PaymentOrder:
    """
    1. Creates an order on Razorpay
    2. Saves a PaymentOrder record in our database
    Returns the PaymentOrder instance.
    """
    fee = amount if amount is not None else appointment.consultation_fee
    amount_paise = int(float(fee) * 100)

    rz_order = _client.order.create({
        'amount':          amount_paise,
        'currency':        'INR',
        'receipt':         f'appt_{appointment.id}',
        'payment_capture': 1,
    })

    payment_order = PaymentOrder.objects.create(
        appointment=appointment,
        patient=patient,
        amount=fee,
        currency='INR',
        gateway_order_id=rz_order['id'],
        status='created',
    )
    return payment_order


def verify_razorpay_payment(
    payment_order: PaymentOrder,
    razorpay_payment_id: str,
    razorpay_signature: str,
) -> bool:
    """
    Verifies the HMAC-SHA256 signature that Razorpay sends back.
    This MUST happen on the backend — never trust the Flutter side.
    Returns True if signature is valid, False otherwise.
    """
    message = f"{payment_order.gateway_order_id}|{razorpay_payment_id}"
    expected_signature = hmac.new(
        settings.RAZORPAY_KEY_SECRET.encode('utf-8'),
        message.encode('utf-8'),
        hashlib.sha256,
    ).hexdigest()

    # timing-safe comparison — prevents timing attacks
    is_valid = hmac.compare_digest(expected_signature, razorpay_signature)

    # Save the transaction record regardless (for audit trail)
    PaymentTransaction.objects.create(
        order=payment_order,
        gateway_payment_id=razorpay_payment_id,
        gateway_signature=razorpay_signature,
        is_verified=is_valid,
    )

    if is_valid:
        payment_order.status = 'paid'
        payment_order.paid_at = timezone.now()
        payment_order.save(update_fields=['status', 'paid_at'])

        # Move appointment from pending_payment → scheduled (confirmed & paid)
        payment_order.appointment.status = 'scheduled'
        payment_order.appointment.save(update_fields=['status'])

    return is_valid
