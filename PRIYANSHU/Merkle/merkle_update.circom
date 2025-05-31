pragma circom 2.0.0;

include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/mux1.circom";

// Template for Merkle tree inclusion proof and root update
template MerkleTreeUpdate() {
    // Public inputs
    signal input oldRoot;           // Original root before transaction
    signal input newRoot;           // Expected new root after transaction
    signal input transactionHash;  // Hash of the transaction
    
    // Private inputs (witness)
    signal input leafIndex;        // Index of the leaf being updated (0-3 for 2-level tree)
    signal input oldLeafValue;     // Original value of the leaf
    signal input newLeafValue;     // New value of the leaf after transaction
    signal input pathElements[2];  // Sibling elements for the path
    signal input pathIndices[2];   // Path indices (0 = left, 1 = right)
    
    // Output
    signal output isValid;
    
    // Verify that the transaction hash is correctly computed
    component transactionHasher = Poseidon(2);
    transactionHasher.inputs[0] <== oldLeafValue;
    transactionHasher.inputs[1] <== newLeafValue;
    transactionHasher.out === transactionHash;
    
    // Verify old root
    component oldPathHashers[2];
    component oldSelectors[2];
    
    // Level 0 (leaf level)
    oldSelectors[0] = Mux1();
    oldSelectors[0].c[0] <== oldLeafValue;
    oldSelectors[0].c[1] <== pathElements[0];
    oldSelectors[0].s <== pathIndices[0];
    
    oldPathHashers[0] = Poseidon(2);
    oldPathHashers[0].inputs[0] <== oldSelectors[0].out;
    oldPathHashers[0].inputs[1] <== pathElements[0];
    
    // Level 1 (root level)
    oldSelectors[1] = Mux1();
    oldSelectors[1].c[0] <== oldPathHashers[0].out;
    oldSelectors[1].c[1] <== pathElements[1];
    oldSelectors[1].s <== pathIndices[1];
    
    oldPathHashers[1] = Poseidon(2);
    oldPathHashers[1].inputs[0] <== oldSelectors[1].out;
    oldPathHashers[1].inputs[1] <== pathElements[1];
    
    // Verify that computed old root matches input
    oldPathHashers[1].out === oldRoot;
    
    // Compute new root with updated leaf
    component newPathHashers[2];
    component newSelectors[2];
    
    // Level 0 (leaf level) with new value
    newSelectors[0] = Mux1();
    newSelectors[0].c[0] <== newLeafValue;
    newSelectors[0].c[1] <== pathElements[0];
    newSelectors[0].s <== pathIndices[0];
    
    newPathHashers[0] = Poseidon(2);
    newPathHashers[0].inputs[0] <== newSelectors[0].out;
    newPathHashers[0].inputs[1] <== pathElements[0];
    
    // Level 1 (root level)
    newSelectors[1] = Mux1();
    newSelectors[1].c[0] <== newPathHashers[0].out;
    newSelectors[1].c[1] <== pathElements[1];
    newSelectors[1].s <== pathIndices[1];
    
    newPathHashers[1] = Poseidon(2);
    newPathHashers[1].inputs[0] <== newSelectors[1].out;
    newPathHashers[1].inputs[1] <== pathElements[1];
    
    // Verify that computed new root matches expected new root
    newPathHashers[1].out === newRoot;
    
    // Additional constraint: ensure leaf index is within valid range (0-3 for 2-level tree)
    component leafIndexCheck = LessThan(3);
    leafIndexCheck.in[0] <== leafIndex;
    leafIndexCheck.in[1] <== 4; // 2^2 = 4 leaves max
    leafIndexCheck.out === 1;
    
    // If all constraints pass, the proof is valid
    isValid <== 1;
}

// Helper template to check if a number is less than another
template LessThan(n) {
    assert(n <= 252);
    signal input in[2];
    signal output out;
    
    component lt = Num2Bits(n+1);
    lt.in <== in[0] + (1<<n) - in[1];
    
    out <== 1 - lt.out[n];
}

// Helper template to convert number to bits
template Num2Bits(n) {
    signal input in;
    signal output out[n];
    var lc1=0;
    
    var e2=1;
    for (var i = 0; i<n; i++) {
        out[i] <-- (in >> i) & 1;
        out[i] * (out[i] -1 ) === 0;
        lc1 += out[i] * e2;
        e2 = e2+e2;
    }
    
    lc1 === in;
}

component main = MerkleTreeUpdate();
