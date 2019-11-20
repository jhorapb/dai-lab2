/***
* Name: festival_auctions_challenge1
* Author: Jhorman Perez and Wilfredo Robinson
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model festival_auctions_challenge1

/* Insert your model definition here */
global {
	
	bool conversationRunning;
	int nbOfParticipants <- 1;
	bool pauseProgram;
	//bool resetAuction;
	//bool initiatorCreated <- true;
	//bool priceAdjusted;
	//bool startConversation;
	//list<int> controlRefuses <- [];
	//bool allRefused;
	//bool winnerDeclared;
	list<string> auctionTypes <- ['technology', 'literature', 'cinema', 'sports', 'kitchen'];
	list<rgb> auctionColor <- [#blue, #purple, #black, #peru, #violet];
	
	init {
		create initiator number: 1 {}
		create participant number: nbOfParticipants returns: ps {} 
	}
	
	reflex pauseSimulation when: pauseProgram {
		do pause;
	}
}

species initiator skills: [fipa, moving] {
	
	rgb agentColor;
	image_file icon;
	bool cycleZero;
	float itemPrice;
	int initCycle;
	list<message> participantMessages;
	list<int> controlRefuses <- [];
	bool resetAuction;
	bool startConversation;
	bool allRefused;
	bool priceAdjusted;
	bool winnerDeclared;
	float initialPrice;
	point targetPoint;
	int adjustCycle;
	string itemType;
	bool allRefuse;
	bool initiatorCreated <- true;
	
	init {
		agentColor <- #purple;
		//icon <- image_file("../includes/img/EricCartman.png");
		cycleZero <- true;
	}
	
	aspect default {
			draw icon size: 6;
			draw cube(4) at: location color: agentColor;
	}
	
	//Participants move while an auction is NOT in place
	reflex beIdle when: empty(cfps) {
		write '=====================WANDER INITIATOR' color: #red;
		do wander speed: speed;
	}
	
	//Auctioneer appears every set amount of cycles
	reflex initiatorAppear {
		if cycleZero {
			write '=====================CYCLE ZERO' color: #red;
			initCycle <- cycle;
			cycleZero <- false;
			resetAuction <- false;
			pauseProgram <- false;
			itemPrice <- float(rnd(2000, 3000));
			initialPrice <- itemPrice;
			winnerDeclared <- false;
			int typeIndex <- rnd(length(auctionTypes) - 1);
			itemType <- auctionTypes[typeIndex];
			agentColor <- auctionColor[typeIndex];
			ask participant {
				write 'The initial budget of ' + self.name + ' for this auction is $' + self.budget;
				write '\t ' + self.name + ' likes ' + self.preferences;
				
			}
		}
		//CFP message is sent to all participants
		else if (cycle - initCycle = 10000) {
			write '=====================CYCLE 10K' color: #red;
			conversationRunning <- true;
			startConversation <- true;
		}
		
		if (cycle - initCycle = 9999){
			write '=====================PAUSE PROGRAM' color: #red;
			pauseProgram <- true;
		}
		if (priceAdjusted or startConversation) and !allRefused and !winnerDeclared {
			write '=====================CONVERSATION START!' color: #red;
			allRefused <- false;
			controlRefuses <- [];
			do start_conversation with: [ to :: list(participant), protocol :: 'no-protocol', performative :: 'inform', contents :: []];
			do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', 
				performative :: 'cfp', contents :: [itemPrice, itemType, agentColor]];
			write name + ' (type: ' + itemType + ', color: ' + agentColor + ') sends a cfp message to all guests' color: agentColor;
			write 'The price of this item is $' + itemPrice color: agentColor ;
		}
	}
	
	//Auctioneer receives propose messages from participants
	reflex receive_propose_messages when: !empty(proposes) {
		write '=====================DECLARE WINNER' color: #red;
		message proposeMessageReceived <- proposes[0];
		add all: proposes to: participantMessages; 
		write 'We have a winner! The winner is ' + proposeMessageReceived.sender + 'for a price of $' + itemPrice color: #orange ;
		do accept_proposal with: [ message :: proposeMessageReceived, contents :: [itemPrice]];
		
		loop p over: proposes {
			write '=====================REJECT OTHER PROPOSALS' color: #red;
			write 'Auctioneer has rejected the proposal from ' + p.sender color: agentColor ;
			do reject_proposal with: [ message :: p, contents :: [] ];
		}
		ask participant {
			if self.auctioneerName = myself.name {
				write '=====================ASK PARTICIPANT TO RESET AGENT WHEN HE PROPOSES' color: #red;
				self.alreadyInAuction <- false;
				self.agentColor <- #yellow;
				self.auctioneerName <- nil;
			}
			
		}		
	}
		
	//Auctioneer receives refuse messages from participants
	reflex receive_refuse_messages when: !empty(refuses) {
		add all: refuses to: participantMessages;
		ask participant {
			if self.auctioneerName = myself.name {
				write '=====================ASK PARTICIPANT TO RESET AGENT WHEN HE REFUSES' color: #red;
				self.alreadyInAuction <- false;
				self.agentColor <- #yellow;
				self.auctioneerName <- nil;
			}
		}
	}
	
	/*
	 * System resets the auction process
	 */
	reflex resetAuction when: resetAuction {
		write '=====================RESET AUCTION' color: #red;
		cycleZero <- true;
		initCycle <- 0;
		conversationRunning <- false;
		pauseProgram <- false;
		allRefused <- false;
		winnerDeclared <- false;
		
//		loop p over: participantMessages {
//			do end_conversation with: [ message :: p, contents :: [false] ];
//		}
	}
	
	/*
	 * Auctioneer did not receive any proposals. Proceeds to adjust price and start bidding process again
	 */
	reflex adjustPrice when: allRefused {
		write '=====================ENTERED ADJUST PRICE' color: #red;
		if (itemPrice >= 0.5 * initialPrice) {
			write '=====================PROCEEDING TO ADJUST PRICE' color: #red;
			write 'No one participated...so I will decrease the price a bit!' color: agentColor;
			itemPrice <- itemPrice * 0.9;
			priceAdjusted <- true;
			controlRefuses <- [];	
		}
		else {
			write '=====================NO ONE COULD BUY IT AFTER ADJUSTING PRICE' color: #red;
			write 'Oh come on!!! This was too big a bargain and none of you appreciated it. This auction is now closed!' color: agentColor;
			priceAdjusted <- false;
			resetAuction <- true;
			initiatorCreated <- false;
		}
		write '=====================RESETTING ALLREFUSED' color: #red;
		allRefused <- false;
	}
}

species participant skills: [fipa, moving]{
	
	float budget;
	rgb agentColor;
	image_file icon;
	point targetPoint;
	list<string> preferences;
	bool alreadyInAuction;
	string auctioneerName;
	point auctioneerLocation;
	rgb auctioneerColor;

	
	init {
		budget <- float(rnd(2000, 2100));
		add auctionTypes[rnd(length(auctionTypes) - 1)] to: preferences;
		//add auctionTypes[rnd(length(auctionTypes) - 1)] to: preferences;
	}
	
	aspect default {
			draw icon size: 6;
			draw sphere(1.5) at: location color: agentColor;
	}
	
	reflex moveToTarget when: alreadyInAuction {
		write '=====================PARTICIPANT MOVE TO TARGET' color: #red;
		do goto target:{auctioneerLocation.x - 2, auctioneerLocation.y - 2} speed: 0.5;
	}
	
	//Auctioneers move while an auction is NOT in place
	reflex beIdle when: empty(cfps) and !alreadyInAuction {
		write '=====================WANDER PARTICIPANT' color: #red;
		do wander speed: 0.5;
	}
	
	//Participants receive CFP messages
	reflex receive_cfp_from_initiator when: conversationRunning and !empty(cfps) {
		write '=====================PARTICIPANT RECEIVED CFP FROM INITIATOR' color: #red;
		message proposalFromInitiator <- cfps[0];
		list<int> auctionParticipants;
		
		ask participant {
			write '=====================ASKED PARTICIPANT IF HE WILL SEND A PROPOSAL' color: #red;
			if (preferences contains proposalFromInitiator.contents[1] and !alreadyInAuction ){
				write '=====================SAVING AUCTIONEER NAME LOCATION COLOR AND ADDING TO AUCTIONPARTICIPANTS LIST' color: #red;
				auctioneerName <- agent(proposalFromInitiator.sender).name;
				auctioneerLocation <- agent(proposalFromInitiator.sender).location;
				agentColor <- proposalFromInitiator.contents[2];
				add 1 to: auctionParticipants;
				
				//Participant checks his budget and sends his proposal
				if (budget - float(proposalFromInitiator.contents[0]) > 0.05 * budget){
					write '=====================PARTICIPANT HAS THE BUDGET' color: #red;
					write '\t Hey ' + agent(proposalFromInitiator.sender).name + 
					' My name is ' + name + ' and I want to buy!' color: #green ;
					write '\t(My current budget is $' + budget + ' so I should be ok)' color: #green;
					do propose with: [ message :: proposalFromInitiator, contents :: [true] ];
					alreadyInAuction <- true;
					write '=====================PARTICIPANT PROPOSED AND ALREADYINAUCTION' color: #red;
					ask initiator{
						if (myself.auctioneerName = self.name){
							write '=====================ASKED INITIATOR TO WINNERDECLARED=TRUE' color: #red;
							winnerDeclared <- true;
						}
					}
				}
				
				//Participant declines because he does not have a high enough budget
				else{
					write '=====================PARTICIPANT DECLINES' color: #red;
					write '\t Hey ' + agent(proposalFromInitiator.sender).name + ' My name is ' + name + 
					' and I think it\'s too expensive!' color: #red ;
					write '\t (My current budget is $' + budget + ' so I cannnot afford it!)' color: #red ;
					do refuse with: [ message :: proposalFromInitiator, contents :: [false] ];
					write '=====================PARTICIPANT REFUSED AND WILL NOW ASK INITIATOR' color: #red;
					ask initiator{
						if (myself.auctioneerName = self.name){
							write '=====================ADDING 1 TO CONTROL REFUSES' color: #red;
							add 1 to: controlRefuses;
						}
					}
				}
			}	
		}
		ask initiator{
			write '=====================ASKING INITIATOR TO STARTCONVERSATION FALSE' color: #red;
			if (myself.auctioneerName = self.name){
				startConversation <- false;
				if (length(controlRefuses) = length(auctionParticipants) and length(auctionParticipants) !=0 ){
					write '=====================ENTERED TO MAKE ALLREFUSES TRUE' color: #red;
					write '///////////////////////////////////';
					write 'controlRefuses is ' + controlRefuses;
					write 'auctionParticipants is ' + auctionParticipants;
					write '///////////////////////////////////';
					allRefused <- true;
				}
				else if (length(controlRefuses) = length(auctionParticipants) and length(auctionParticipants) !=0 ){
					resetAuction <- true;
				}
			}
		}
		
	}
	
	/*
	 * Participant receives the accept proposal and adjusts his budget. He then sends his inform message. 
	 */
	reflex receive_accept_proposals when: conversationRunning and !empty(accept_proposals) {
		write '=====================PARTICIPANT RECEIVES ACCEPT PROPOSAL' color: #red;
		message acceptProposalFromInitiator <- accept_proposals[0];
		write name + ' receives an accept_proposal message from ' + agent(acceptProposalFromInitiator.sender).name;
		budget <- budget - float(acceptProposalFromInitiator.contents[0]);
		write name + ' has adjusted his remaining budget. It is now: $' + budget;
		write 'This auction is now closed!'color: #red ;
		alreadyInAuction <- false;
		ask initiator{
			if (myself.auctioneerName = self.name){
				self.priceAdjusted <- false;
				self.resetAuction <- true;
				self.initiatorCreated <- false;		
			}
		}
	}
	
	/*
	 * Create a new initiator once an auction ends
	 */
	reflex create_new_initiator{
		ask initiator{
			if (myself.auctioneerName = self.name and self.resetAuction and !self.initiatorCreated) {
				write '=====================PROCEEDING TO KILL INITIATOR' color: #red;
				do die;
				write 'Previous auctioneer has left the scene.';
				create initiator number: 1 {}
				write 'New auctioneer enters the scene and starts preparing the auction';
				//initiatorCreated <- true;
			}
		}
	}
} 
	


experiment main type: gui {
	output {
		display map type: opengl {
			species initiator;
			species participant;
			}
	}
}
