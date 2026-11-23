const test = require("node:test");
const assert = require("node:assert/strict");
const { validatePaymentDecision } = require("../validation/paymentVerification");

test("rejects invalid identifiers and decisions", () => {
  assert.equal(validatePaymentDecision("not-an-id", { status: "approved", cash_received: true }).error, "Invalid order ID.");
  assert.equal(validatePaymentDecision("0", { status: "rejected" }).error, "Invalid order ID.");
  assert.equal(validatePaymentDecision("9007199254740992", { status: "rejected" }).error, "Invalid order ID.");
  assert.equal(validatePaymentDecision("5", { status: "paid" }).error, "Status must be approved or rejected.");
});

test("does not permit approval without confirmed physical cash receipt", () => {
  assert.equal(validatePaymentDecision("5", { status: "approved" }).error, "Confirm that cash was received before approving.");
  assert.equal(validatePaymentDecision("5", { status: "approved", cash_received: "true" }).error, "Confirm that cash was received before approving.");
  assert.deepEqual(validatePaymentDecision("5", { status: "approved", cash_received: true }), { orderId: 5, status: "approved" });
});

test("allows an explicit rejection without claiming payment", () => {
  assert.deepEqual(validatePaymentDecision("5", { status: "rejected" }), { orderId: 5, status: "rejected" });
});
