/**
 * Validate payment decisions without trusting client-supplied payment amounts
 * or employee IDs. The route resolves staff identity from the verified token.
 */
function validatePaymentDecision(rawOrderId, body) {
  if (typeof rawOrderId !== "string" || !/^[1-9]\d*$/.test(rawOrderId)) {
    return { error: "Invalid order ID." };
  }
  const orderId = Number(rawOrderId);
  if (!Number.isSafeInteger(orderId)) {
    return { error: "Invalid order ID." };
  }
  if (!body || !["approved", "rejected"].includes(body.status)) {
    return { error: "Status must be approved or rejected." };
  }
  if (body.status === "approved" && body.cash_received !== true) {
    return { error: "Confirm that cash was received before approving." };
  }
  return { orderId, status: body.status };
}

module.exports = { validatePaymentDecision };
