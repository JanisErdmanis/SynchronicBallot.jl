# SharedBallot anonymous and unique message registration protocol 

Essential part of PeaceVote electronic voting system is in establishing anonymous public key ledger. The simplest ways of performing paper bailout with public keys or making a BalticWay where people cover their faces and show public keys are not practical although very entertaining. 

One of the ways to have the anonymous public key burned in the card by the Vendoor who then gives the card to the state for postprocessing. And when card is being sent ready to the local authorities the unlock key is sent to the place from the Vendoor. There at local authority the person can register his anonymous public key safely.

The second way is by starting with an elligible person public keys and use them to register anonymous public keys. The procedure for registrating a unique message:

(1) The potential member establishes a secure connection with the keyserver. Keyserver checks that user public key is elligible. User checks that he had connected the right server. 
(2) The keyserver generates and sends to the user a blockkey at the moment when N elligible members had reached this stage to make a block full. 
(3) User uses TOR or other ip anonymizer and estblishes the anonymous connection with keyserver which he secures with blockkey. That acts as verification of the server that the right person had contacted him.
(4) User sends his unique message in a random time withn the interval which was specified in the blockey. He waits until delivery time had ended and closes the secure connection.
(5) The block is constructed by the server and sent over the secure connection to each user.
(6) The user checks if his unique message is in the block and sends back a user signature of the block to the server.

To use it for PeaceVote mobile system we use user generated public key as a message. Then inthat wya an anonymous public key ledger can be obtained. Remearkably the procedure then can be repeated then with anonymous keys and that would produce a ledger with even higher anonymity!

Secrecy in this protocol was used only to prevent a block spoiling attacks by the person in the middle. The attacks still can be made by a dishonest potential member who then can register multiple public keys. However such block would never be accepted and thus signed by all elligible memebers. If problem persists one can try to isolate/rearange dishonest memeber until the procedure succeeds.
