pragma circom 2.0.0;

include"circomlib/circuits/poseidon.circom";

template Main(){
 signal input a;
 signal input b;
 signal output out;

signal inputs[2];
inputs[0] <== a;
inputs[1] <== b;
component hasher = Poseidon(2);
hasher.inputs[0]<== inputs[0];
hasher.inputs[1]<== inputs[1];
out<==hasher.out;
}
component main= Main();
