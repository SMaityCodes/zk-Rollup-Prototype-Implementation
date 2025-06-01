pragma circom 2.0.0;

include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/comparators.circom";

template ComputeLevelHash() {
    signal input leafValue;
    signal input pathElement;
    signal input pathIndex;
    signal output hash;

    // Determine if path is right (1) or left (0)
    component isRight = IsEqual();
    isRight.in[0] <== pathIndex;
    isRight.in[1] <== 1;

    // Break down the computation into quadratic steps
    signal leftTerm1;
    signal leftTerm2;
    signal rightTerm1;
    signal rightTerm2;
    
    // First compute the products separately
    leftTerm1 <== leafValue * (1 - isRight.out);
    leftTerm2 <== pathElement * isRight.out;
    
    rightTerm1 <== pathElement * (1 - isRight.out);
    rightTerm2 <== leafValue * isRight.out;

    // Then sum them (addition is quadratic)
    signal left;
    signal right;
    left <== leftTerm1 + leftTerm2;
    right <== rightTerm1 + rightTerm2;

    // Poseidon hash of the two values
    component h = Poseidon(2);
    h.inputs[0] <== left;
    h.inputs[1] <== right;
    hash <== h.out;
}

template MerkleTreeDoubleUpdate() {
    signal input oldRoot;
    signal output newRoot;

    // First leaf update inputs
    signal input leafIndex1;
    signal input oldLeafValue1;
    signal input newLeafValue1;
    signal input pathElements1[2];
    signal input pathIndices1[2];

    // Second leaf update inputs
    signal input leafIndex2;
    signal input oldLeafValue2;
    signal input newLeafValue2;
    signal input pathElements2[2];
    signal input pathIndices2[2];

    // === Input Validation ===
    // Ensure leaf indices are different
    component indexDiff = IsEqual();
    indexDiff.in[0] <== leafIndex1;
    indexDiff.in[1] <== leafIndex2;
    indexDiff.out === 0;

    // Ensure leaf indices are valid (0-3 for 2-level tree)
    component check1 = LessThan(32);
    check1.in[0] <== leafIndex1;
    check1.in[1] <== 4;
    check1.out === 1;

    component check2 = LessThan(32);
    check2.in[0] <== leafIndex2;
    check2.in[1] <== 4;
    check2.out === 1;

    // === Old root verification ===
    component oldHash1_level0 = ComputeLevelHash();
    oldHash1_level0.leafValue <== oldLeafValue1;
    oldHash1_level0.pathElement <== pathElements1[0];
    oldHash1_level0.pathIndex <== pathIndices1[0];

    component oldHash1_level1 = ComputeLevelHash();
    oldHash1_level1.leafValue <== oldHash1_level0.hash;
    oldHash1_level1.pathElement <== pathElements1[1];
    oldHash1_level1.pathIndex <== pathIndices1[1];

    component oldHash2_level0 = ComputeLevelHash();
    oldHash2_level0.leafValue <== oldLeafValue2;
    oldHash2_level0.pathElement <== pathElements2[0];
    oldHash2_level0.pathIndex <== pathIndices2[0];

    component oldHash2_level1 = ComputeLevelHash();
    oldHash2_level1.leafValue <== oldHash2_level0.hash;
    oldHash2_level1.pathElement <== pathElements2[1];
    oldHash2_level1.pathIndex <== pathIndices2[1];

    oldHash1_level1.hash === oldRoot;
    oldHash2_level1.hash === oldRoot;

    // === New root computation ===
    component newHash1_level0 = ComputeLevelHash();
    newHash1_level0.leafValue <== newLeafValue1;
    newHash1_level0.pathElement <== pathElements1[0];
    newHash1_level0.pathIndex <== pathIndices1[0];

    component newHash1_level1 = ComputeLevelHash();
    newHash1_level1.leafValue <== newHash1_level0.hash;
    newHash1_level1.pathElement <== pathElements1[1];
    newHash1_level1.pathIndex <== pathIndices1[1];

    component newHash2_level0 = ComputeLevelHash();
    newHash2_level0.leafValue <== newLeafValue2;
    newHash2_level0.pathElement <== pathElements2[0];
    newHash2_level0.pathIndex <== pathIndices2[0];

    component newHash2_level1 = ComputeLevelHash();
    newHash2_level1.leafValue <== newHash2_level0.hash;
    newHash2_level1.pathElement <== pathElements2[1];
    newHash2_level1.pathIndex <== pathIndices2[1];

    newHash1_level1.hash === newHash2_level1.hash;
    newRoot <== newHash1_level1.hash;
}

component main {public [oldRoot]} = MerkleTreeDoubleUpdate();
