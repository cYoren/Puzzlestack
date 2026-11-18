import 'dart:math';

class FactorNode {
  final int index;
  int value;
  bool isPrime;
  bool isSolved;
  bool isVisible;

  FactorNode({
    required this.index,
    required this.value,
    required this.isPrime,
    this.isSolved = false,
    this.isVisible = false,
  });
}

class PrimeFactorTreesEngine {
  final Random _random;
  final List<int> _puzzleRoots = const [
    12, 18, 20, 24, 27, 28, 30, 36, 40, 42,
    44, 45, 50, 52, 54, 56, 60, 63, 66, 68,
    70, 75, 76, 84, 90, 98, 99,
  ];

  List<int> get puzzleRoots => _puzzleRoots;

  late int rootValue;
  late Map<int, FactorNode> treeNodes;
  List<int> options = [];

  PrimeFactorTreesEngine({Random? random}) : _random = random ?? Random();

  void generatePuzzle({int? root}) {
    rootValue = root ?? _puzzleRoots[_random.nextInt(_puzzleRoots.length)];
    treeNodes = {
      1: FactorNode(
        index: 1,
        value: rootValue,
        isPrime: false,
        isSolved: true,
        isVisible: true,
      ),
      2: FactorNode(
        index: 2,
        value: 0,
        isPrime: false,
        isSolved: false,
        isVisible: true,
      ),
      3: FactorNode(
        index: 3,
        value: 0,
        isPrime: false,
        isSolved: false,
        isVisible: true,
      ),
    };
    generateOptions();
  }

  bool isPrime(int n) {
    if (n < 2) return false;
    for (int i = 2; i * i <= n; i++) {
      if (n % i == 0) return false;
    }
    return true;
  }

  bool isProductOfTwoPrimes(int n) {
    for (int i = 2; i * i <= n; i++) {
      if (n % i == 0) {
        return isPrime(i) && isPrime(n ~/ i);
      }
    }
    return false;
  }

  List<int> getValidFactors(int nodeIndex) {
    final parent = treeNodes[nodeIndex ~/ 2];
    if (parent == null || !parent.isSolved) return [];

    final parentVal = parent.value;
    final siblingIndex = nodeIndex.isEven ? nodeIndex + 1 : nodeIndex - 1;
    final sibling = treeNodes[siblingIndex];

    if (sibling != null && sibling.isSolved) {
      if (parentVal % sibling.value != 0) return [];
      final needed = parentVal ~/ sibling.value;
      if (nodeIndex >= 4) {
        return isPrime(needed) ? [needed] : [];
      } else {
        return (isPrime(needed) || isProductOfTwoPrimes(needed)) ? [needed] : [];
      }
    }

    final valid = <int>[];
    for (int f = 2; f < parentVal; f++) {
      if (parentVal % f != 0) continue;
      final other = parentVal ~/ f;
      if (nodeIndex >= 4) {
        if (isPrime(f) && isPrime(other)) {
          valid.add(f);
        }
      } else {
        final fValid = isPrime(f) || isProductOfTwoPrimes(f);
        final otherValid = isPrime(other) || isProductOfTwoPrimes(other);
        if (fValid && otherValid) {
          valid.add(f);
        }
      }
    }
    return valid;
  }

  void generateOptions() {
    final guaranteed = <int>{};
    final validPool = <int>{};
    for (final node in treeNodes.values) {
      if (node.isVisible && !node.isSolved) {
        final factors = getValidFactors(node.index);
        if (factors.isNotEmpty) {
          guaranteed.add(factors[_random.nextInt(factors.length)]);
          validPool.addAll(factors);
        }
      }
    }

    final optionSet = <int>{...guaranteed};
    final remainingValid = validPool.difference(optionSet).toList()
      ..shuffle(_random);
    for (final v in remainingValid) {
      if (optionSet.length >= 6) break;
      optionSet.add(v);
    }

    int guard = 0;
    while (optionSet.length < 6 && guard < 100) {
      guard++;
      optionSet.add(_random.nextInt(12) + 2);
    }

    final list = optionSet.toList()..shuffle(_random);
    options = list.length > 6 ? list.sublist(0, 6) : list;
  }

  bool submitAnswer(int nodeIndex, int value) {
    final targetNode = treeNodes[nodeIndex];
    if (targetNode == null || targetNode.isSolved || !targetNode.isVisible) {
      return false;
    }

    final validFactors = getValidFactors(nodeIndex);
    if (!validFactors.contains(value)) {
      return false;
    }

    targetNode.value = value;
    targetNode.isPrime = isPrime(value);
    targetNode.isSolved = true;

    final siblingIndex = nodeIndex.isEven ? nodeIndex + 1 : nodeIndex - 1;
    final sibling = treeNodes[siblingIndex];
    final parent = treeNodes[nodeIndex ~/ 2];
    if (parent != null && sibling != null && !sibling.isSolved) {
      final siblingVal = parent.value ~/ value;
      sibling.value = siblingVal;
      sibling.isPrime = isPrime(siblingVal);
    }

    if (nodeIndex < 4 && !targetNode.isPrime) {
      final leftChildIdx = nodeIndex * 2;
      final rightChildIdx = nodeIndex * 2 + 1;
      treeNodes[leftChildIdx] = FactorNode(
        index: leftChildIdx,
        value: 0,
        isPrime: true,
        isSolved: false,
        isVisible: true,
      );
      treeNodes[rightChildIdx] = FactorNode(
        index: rightChildIdx,
        value: 0,
        isPrime: true,
        isSolved: false,
        isVisible: true,
      );
    }

    generateOptions();
    return true;
  }

  bool isSolved() {
    return treeNodes.values.where((n) => n.isVisible).every((n) => n.isSolved);
  }
}
