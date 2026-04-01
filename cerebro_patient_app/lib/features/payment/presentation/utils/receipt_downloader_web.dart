// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadReceipt({
  required String doctorName,
  required String specialization,
  required String clinicName,
  required String date,
  required String time,
  required double consultationFee,
  required int appointmentId,
  required String? paymentId,
}) {
  final feeStr = '₹${consultationFee.toStringAsFixed(0)}';
  final txnRow = paymentId != null && paymentId.isNotEmpty
      ? '<div class="row"><span class="lbl">Transaction ID</span><span class="val small">$paymentId</span></div>'
      : '';

  final content = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Payment Receipt — Cerebro</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Segoe UI',sans-serif;background:#F0F7F8;padding:40px 20px;color:#0D2137}
    .card{background:#fff;max-width:540px;margin:0 auto;border-radius:16px;overflow:hidden;box-shadow:0 8px 32px rgba(0,0,0,.10)}
    .header{background:#14919B;padding:28px 32px;text-align:center;color:#fff}
    .logo{font-size:26px;font-weight:800;letter-spacing:1px}
    .sub{font-size:13px;opacity:.85;margin-top:4px}
    .badge{display:inline-block;background:rgba(255,255,255,.25);border-radius:20px;padding:4px 18px;font-size:12px;font-weight:700;margin-top:10px;letter-spacing:.5px}
    .body{padding:28px 32px}
    .receipt-title{font-size:15px;font-weight:700;color:#14919B;margin-bottom:18px;padding-bottom:10px;border-bottom:2px solid #F0F7F8}
    .row{display:flex;justify-content:space-between;align-items:center;padding:9px 0;border-bottom:1px solid #F0F7F8}
    .lbl{font-size:12px;color:#5A6A7E;font-weight:500}
    .val{font-size:13px;font-weight:600;color:#0D2137;text-align:right;max-width:60%}
    .small{font-size:11px;font-family:monospace}
    .total{display:flex;justify-content:space-between;align-items:center;padding:16px 0 0;margin-top:6px}
    .total-lbl{font-size:16px;font-weight:700}
    .total-val{font-size:22px;font-weight:800;color:#14919B}
    .paid{text-align:center;margin:20px 0 10px}
    .paid-badge{display:inline-block;background:#D1FAE5;color:#10B981;font-size:13px;font-weight:700;padding:6px 24px;border-radius:20px;letter-spacing:.5px}
    .footer{text-align:center;color:#94A3B8;font-size:11px;padding:16px 32px 24px;background:#F8FCFC}
    @media print{body{background:#fff}.card{box-shadow:none}}
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <div class="logo">Cerebro</div>
      <div class="sub">Mental Health Platform</div>
      <div class="badge">PAYMENT RECEIPT</div>
    </div>
    <div class="body">
      <div class="receipt-title">Receipt #APT-$appointmentId</div>
      <div class="row"><span class="lbl">Doctor</span><span class="val">Dr. $doctorName</span></div>
      <div class="row"><span class="lbl">Specialization</span><span class="val">$specialization</span></div>
      <div class="row"><span class="lbl">Clinic</span><span class="val">$clinicName</span></div>
      <div class="row"><span class="lbl">Appointment Date</span><span class="val">$date</span></div>
      <div class="row"><span class="lbl">Appointment Time</span><span class="val">$time</span></div>
      $txnRow
      <div class="total"><span class="total-lbl">Amount Paid</span><span class="total-val">$feeStr</span></div>
      <div class="paid"><span class="paid-badge">✓ PAYMENT CONFIRMED</span></div>
    </div>
    <div class="footer">
      <p>Thank you for choosing Cerebro Health</p>
      <p style="margin-top:4px">This is a system-generated receipt and does not require a signature.</p>
    </div>
  </div>
  <div style="text-align:center;margin-top:20px">
    <button onclick="window.print()" style="background:#14919B;color:#fff;border:none;padding:10px 32px;border-radius:8px;font-size:14px;cursor:pointer;font-weight:600">
      🖨 Print / Save as PDF
    </button>
  </div>
</body>
</html>''';

  final blob = html.Blob([content], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..download = 'cerebro_receipt_appt_$appointmentId.html'
    ..click();
  html.Url.revokeObjectUrl(url);
  anchor.remove();
}
