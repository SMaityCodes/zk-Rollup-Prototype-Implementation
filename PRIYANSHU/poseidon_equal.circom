pragma circom 2.0.0;
include "circomlib/circuits/poseidon.circom";
include "circomlib/circuits/comparators.circom";

template CheckPoseidonEqualityWithOutput(nInputs){
signal input dataA[nInputs];
signal input dataB[nInputs];
signal output isEqual;

component poseidonA= Poseidon(nInputs);
component poseidonB= Poseidon(nInputs);

for(var i=0;i<nInputs;i++){
poseidonA.inputs[i]<== dataA[i];
poseidonB.inputs[i]<== dataB[i];
}
signal diff;
diff<==poseidonA.out-poseidonB.out;
component isZero=IsZero();
isZero.in <==diff;
isEqual<==isZero.out;
}
component main=CheckPoseidonEqualityWithOutput(2);

