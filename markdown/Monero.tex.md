/chapterMonero the Cryptocurrency /labelchapter:Monero-cryptocurrency

final chapter ties it all together (? technical enough to skip rest of
report? might make it too long - aim to redirect to other parts of
report)

-curve ed25519 -address creation -basic -subaddresses -multisig -payment
ID (integrated addresses) -receipt of old transactions -scan blockchain,
look at output addresses, use view key and transaction public key to see
if any spend keys match -organize results -building transaction
-structure of a transaction (how the data is serialized/organized and
transmitted) -obtain addresses (or subaddresses) of intended recipients,
specify amounts intended for each -from sending amounts + fee, select a
set of owned outputs with amounts sum(a)\>=(sum(b)+fee), and set change
= sum(a) - (sum(b)+fee) -construct outputs: -create transaction public
key (or keys if at least one subaddress and \>1 output) -create one-time
output address for each output -commit to each output amount C(b)
-create D-H 'amount' and 'mask' terms for each output commitment -range
proof: borromean ring signature on each output amount -if payment ids,
encrypt them -construct inputs: -create pseudo output commitments if
transaction type rcttypesimple -select ring members for each input mlsag
-calculate key images for each input -build MLSAG signatures on each
input, signing a message that contains all other transaction info -fill
out transaction data structure appropriately (continuous throughout
transaction procedure) -submission of transaction -verified, placed in
mempool -mining into blockchain -transactions organized into merkle
tree, hashed -nonce searched until difficulty reached -block published
to network -block accepted or rejected (orphaned); consensus mechanism
-\[potential\] signature data pruned
