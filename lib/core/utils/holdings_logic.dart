import '../models/holding.dart';

const weightEpsilon = 0.0001;

bool isDepleted(double weightG) => weightG <= weightEpsilon;

Holding reduceHolding(Holding h, double weightConsumed, double costConsumed) {
  final newWeight = h.weightG - weightConsumed;
  final newCost = h.costBasisMyr - costConsumed;
  return h.copyWith(
    weightG: newWeight < 0 ? 0 : newWeight,
    costBasisMyr: newCost < 0 ? 0 : newCost,
    status: isDepleted(newWeight) ? 'depleted' : h.status,
  );
}

Holding createOutputHolding({
  required String id,
  required String lotId,
  required double outputWeightG,
  required double outputPurity,
  required double costBasisMyr,
  required String label,
}) =>
    Holding(
      id: id,
      lotId: lotId,
      label: label,
      purity: outputPurity,
      weightG: outputWeightG,
      originalWeightG: outputWeightG,
      costBasisMyr: costBasisMyr,
      source: 'exchange',
      status: 'in_hand',
      createdAt: DateTime.now(),
    );

Holding createPurchaseHolding({
  required String id,
  required String lotId,
  required double purity,
  required double weightG,
  required double costBasisMyr,
}) =>
    Holding(
      id: id,
      lotId: lotId,
      label: 'Purchase',
      purity: purity,
      weightG: weightG,
      originalWeightG: weightG,
      costBasisMyr: costBasisMyr,
      source: 'purchase',
      status: 'in_hand',
      createdAt: DateTime.now(),
    );
