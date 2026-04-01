from django.db import models
from appointments.models import Appointment
from accounts.models import User


class PaymentOrder(models.Model):
    STATUS_CHOICES = [
        ('created',  'Created'),
        ('paid',     'Paid'),
        ('failed',   'Failed'),
        ('refunded', 'Refunded'),
    ]

    appointment       = models.OneToOneField(
        Appointment, on_delete=models.CASCADE, related_name='payment_order'
    )
    patient           = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='payment_orders'
    )
    amount            = models.DecimalField(max_digits=10, decimal_places=2)
    currency          = models.CharField(max_length=3, default='INR')
    # ID returned by Razorpay when we create the order
    gateway_order_id  = models.CharField(max_length=255, unique=True)
    status            = models.CharField(
        max_length=20, choices=STATUS_CHOICES, default='created'
    )
    paid_at           = models.DateTimeField(null=True, blank=True)
    created_at        = models.DateTimeField(auto_now_add=True)
    updated_at        = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"PaymentOrder #{self.id} — {self.gateway_order_id} ({self.status})"


class PaymentTransaction(models.Model):
    """Stores the Razorpay callback data after the patient pays."""
    order              = models.ForeignKey(
        PaymentOrder, on_delete=models.CASCADE, related_name='transactions'
    )
    gateway_payment_id = models.CharField(max_length=255)   # razorpay_payment_id
    gateway_signature  = models.CharField(max_length=500)   # razorpay_signature
    is_verified        = models.BooleanField(default=False)
    created_at         = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Txn {self.gateway_payment_id} — verified={self.is_verified}"
