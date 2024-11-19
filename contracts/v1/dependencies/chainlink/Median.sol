// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./SafeMathChainlink.sol";
import "./SignedSafeMath.sol";

// solhint-disable
library Median {
    using SignedSafeMath for int256;

    int256 constant INT_MAX = 2**255 - 1;

    /**
     * @notice Returns the sorted middle, or the average of the two middle indexed items if the
     * array has an even number of elements.
     * @dev The list passed as an argument isn't modified.
     * @dev This algorithm has expected runtime O(n), but for adversarially chosen inputs
     * the runtime is O(n^2).
     * @param list The list of elements to compare
     */
    function calculate(int256[] memory list) internal pure returns (int256) {
        return calculateInplace(copy(list));
    }

    /**
     * @notice See documentation for function calculate.
     * @dev The list passed as an argument may be permuted.
     */
    function calculateInplace(int256[] memory list)
        internal
        pure
        returns (int256)
    {
        require(0 < list.length, "list must not be empty");
        uint256 len = list.length;
        uint256 middleIndex = len / 2;
        if (len % 2 == 0) {
            int256 median1;
            int256 median2;
            (median1, median2) = quickselectTwo(
                list,
                0,
                len - 1,
                middleIndex - 1,
                middleIndex
            );
            return SignedSafeMath.avg(median1, median2);
        } else {
            return quickselect(list, 0, len - 1, middleIndex);
        }
    }

    /**
     * @notice Maximum length of list that shortSelectTwo can handle
     */
    uint256 constant SHORTSELECTTWO_MAX_LENGTH = 20;

    /**
     * @notice Select the k1-th and k2-th element from list of length at most 7
     * @dev Uses an optimal sorting network
     */
    function shortSelectTwo(
        int256[] memory list,
        uint256 lo,
        uint256 hi,
        uint256 k1,
        uint256 k2
    ) private pure returns (int256 k1th, int256 k2th) {
        // Uses an optimal sorting network (https://en.wikipedia.org/wiki/Sorting_network)
        // for lists of length 20. Network layout is taken from
        // http://jgamble.ripco.net/cgi-bin/nw.cgi?inputs=7&algorithm=hibbard&output=svg

        uint256 len = hi + 1 - lo;

        int256[] memory x = new int256[](len);
        for (uint256 i = 0; i < len; i++) {
            x[i] = list[lo + i];
        }

        int256 temp;
        for (uint256 i = 0; i < len; i++) {
            for (uint256 j = len - 1; j > i; j--) {
                if (x[j] < x[j - 1]) {
                    temp = x[j];
                    x[j] = x[j - 1];
                    x[j - 1] = temp;
                }
            }
        }

        uint256 index1 = k1 - lo;
        if (index1 < len) {
            k1th = x[index1];
        } else if (index1 < SHORTSELECTTWO_MAX_LENGTH) {
            k1th = INT_MAX;
        } else {
            revert("k1 out of bounds");
        }

        uint256 index2 = k2 - lo;
        if (index2 < len) {
            return (k1th, x[index2]);
        } else if (index2 < SHORTSELECTTWO_MAX_LENGTH) {
            return (k1th, INT_MAX);
        } else {
            revert("k2 out of bounds");
        }
    }

    /**
     * @notice Selects the k-th ranked element from list, looking only at indices between lo and hi
     * (inclusive). Modifies list in-place.
     */
    function quickselect(
        int256[] memory list,
        uint256 lo,
        uint256 hi,
        uint256 k
    ) private pure returns (int256 kth) {
        require(lo <= k);
        require(k <= hi);
        while (lo < hi) {
            if (hi - lo < SHORTSELECTTWO_MAX_LENGTH) {
                int256 ignore;
                (kth, ignore) = shortSelectTwo(list, lo, hi, k, k);
                return kth;
            }
            uint256 pivotIndex = partition(list, lo, hi);
            if (k <= pivotIndex) {
                // since pivotIndex < (original hi passed to partition),
                // termination is guaranteed in this case
                hi = pivotIndex;
            } else {
                // since (original lo passed to partition) <= pivotIndex,
                // termination is guaranteed in this case
                lo = pivotIndex + 1;
            }
        }
        return list[lo];
    }

    /**
     * @notice Selects the k1-th and k2-th ranked elements from list, looking only at indices between
     * lo and hi (inclusive). Modifies list in-place.
     */
    function quickselectTwo(
        int256[] memory list,
        uint256 lo,
        uint256 hi,
        uint256 k1,
        uint256 k2 // for testing
    ) internal pure returns (int256 k1th, int256 k2th) {
        require(k1 < k2);
        require(lo <= k1 && k1 <= hi);
        require(lo <= k2 && k2 <= hi);

        while (true) {
            if (hi - lo < SHORTSELECTTWO_MAX_LENGTH) {
                return shortSelectTwo(list, lo, hi, k1, k2);
            }
            uint256 pivotIdx = partition(list, lo, hi);
            if (k2 <= pivotIdx) {
                hi = pivotIdx;
            } else if (pivotIdx < k1) {
                lo = pivotIdx + 1;
            } else {
                assert(k1 <= pivotIdx && pivotIdx < k2);
                k1th = quickselect(list, lo, pivotIdx, k1);
                k2th = quickselect(list, pivotIdx + 1, hi, k2);
                return (k1th, k2th);
            }
        }
    }

    /**
     * @notice Partitions list in-place using Hoare's partitioning scheme.
     * Only elements of list between indices lo and hi (inclusive) will be modified.
     * Returns an index i, such that:
     * - lo <= i < hi
     * - forall j in [lo, i]. list[j] <= list[i]
     * - forall j in [i, hi]. list[i] <= list[j]
     */
    function partition(
        int256[] memory list,
        uint256 lo,
        uint256 hi
    ) private pure returns (uint256) {
        // We don't care about overflow of the addition, because it would require a list
        // larger than any feasible computer's memory.
        int256 pivot = list[(lo + hi) / 2];
        lo -= 1; // this can underflow. that's intentional.
        hi += 1;
        while (true) {
            do {
                lo += 1;
            } while (list[lo] < pivot);
            do {
                hi -= 1;
            } while (list[hi] > pivot);
            if (lo < hi) {
                (list[lo], list[hi]) = (list[hi], list[lo]);
            } else {
                // Let orig_lo and orig_hi be the original values of lo and hi passed to partition.
                // Then, hi < orig_hi, because hi decreases *strictly* monotonically
                // in each loop iteration and
                // - either list[orig_hi] > pivot, in which case the first loop iteration
                //   will achieve hi < orig_hi;
                // - or list[orig_hi] <= pivot, in which case at least two loop iterations are
                //   needed:
                //   - lo will have to stop at least once in the interval
                //     [orig_lo, (orig_lo + orig_hi)/2]
                //   - (orig_lo + orig_hi)/2 < orig_hi
                return hi;
            }
        }
    }

    /**
     * @notice Makes an in-memory copy of the array passed in
     * @param list Reference to the array to be copied
     */
    function copy(int256[] memory list)
        private
        pure
        returns (int256[] memory)
    {
        int256[] memory list2 = new int256[](list.length);
        for (uint256 i = 0; i < list.length; i++) {
            list2[i] = list[i];
        }
        return list2;
    }
}