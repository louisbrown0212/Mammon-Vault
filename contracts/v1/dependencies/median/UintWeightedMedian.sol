pragma solidity 0.8.11;

library UintWeightedMedian {
    uint256 constant ONE = 10 ** 18;
    uint256 constant MEDIUM = ONE / 2;

    /**
    * @dev Returns the sorted middle, or the average of the two middle indexed
    * items if the array has an even number of elements
    * @param _list The list of elements to compare
    * @param _weights The weights of elements
    */
    function calculate(
        uint256[] memory _list,
        uint256[] memory _weights
    ) internal pure returns (uint256) {
        uint256 len = _list.length;
        uint256[] memory indexes = new uint256[](len);
        uint256[] memory leftIndexes = new uint256[](len);
        uint256[] memory rightIndexes = new uint256[](len);
        uint256 leftLen;
        uint256 rightLen;
        uint256 prevSum;
        uint256 sum;
        uint256 pivot;
        uint256 i;

        for (i = 0; i < len; i++) {
            indexes[i] = i;
        }

        while (true) {
            pivot = len / 2;
            leftLen = 0;
            rightLen = 0;
            for (i = 0; i < len; i++) {
                if (_list[indexes[i]] < _list[indexes[pivot]]) {
                    leftIndexes[leftLen] = indexes[i];
                    sum += _weights[indexes[i]];
                    leftLen++;
                } else if (_list[indexes[i]] > _list[indexes[pivot]]) {
                    rightIndexes[rightLen] = indexes[i];
                    rightLen++;
                }
            }
            if (sum > MEDIUM) {
                sum = prevSum;
                len = leftLen;
                (indexes, leftIndexes) = (leftIndexes, indexes);
            } else if (ONE - sum - _weights[indexes[pivot]] > MEDIUM) {
                sum += _weights[indexes[pivot]];
                prevSum = sum;
                len = rightLen;
                (indexes, rightIndexes) = (rightIndexes, indexes);
            } else {
                return _list[indexes[pivot]];
            }
        }
    }
}