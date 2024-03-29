/***
* Name: festival_auctions_challenge1
* Author: Jhorman Perez and Wilfredo Robinson
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model festival_auctions_challenge1

global {
	
	int nbOfParticipants <- 3;
	int nbOfInitiators <- 2;
	bool pauseProgram;
	bool stop;
	list<string> auctionTypes <- ['technology', 'literature', 'cinema', 'sports', 'kitchen'];
	list<rgb> auctionColor <- [#blue, #purple, #black, #peru, #violet];

	init {
		create initiator number: nbOfInitiators {}
		create participant number: nbOfParticipants returns: ps {} 
	}
	
	reflex pauseSimulation when: pauseProgram {
		do pause;
	}
	
}

species initiator skills: [fipa, moving] {
	
	rgb agentColor;
	bool allRefused;
	bool conversationRunning;
	image_file icon;
	bool cycleZero;
	list<string> controlRefuses <- [];
	list<message> participantMessages;
	float initialPrice;
	point targetPoint;
	int adjustCycle;
	int initCycle;
	float itemPrice;
	string itemType;
	bool initiatorCreated <- true;
	bool someoneInterested;
	bool winnerDeclared;
	bool resetAuction;
	bool priceAdjusted;
	bool startConversation;
	int numberOfParticipantsInterested;
	int numberOfParticipantsInformed;
	int numberOfParticipantsIgnoring;
	list<string> namesOfParticipantsInformed;
	list<string> namesOfParticipantsInterested;
	list<string> namesOfParticipantsIgnoring;
	int numberForTesting;
	
	init {
		agentColor <- #purple;
		cycleZero <- true;
	}
	
	aspect default {
			draw icon size: 6;
			draw cube(4) at: location color: agentColor;
	}
	
	// Auctioneers move while an auction is NOT in place
	reflex beIdle when: empty(cfps) {
		do wander speed: 0.25;
	}
	
	// Auctioneer appears every set amount of cycles
	reflex initiatorAppear {
		
		if (cycleZero) {
			
			int typeIndex <- rnd(length(auctionTypes) - 1);
			initCycle <- cycle;
			cycleZero <- false;
			resetAuction <- false;
			pauseProgram <- false;
			itemPrice <- float(rnd(2000, 3000));
			initialPrice <- itemPrice;
			itemType <- auctionTypes[typeIndex];
			agentColor <- auctionColor[typeIndex];
			winnerDeclared <- false;
			stop <- false;
			
			ask participant {
				write '\t '+ myself.name + ' says: The initial budget of ' + self.name + ' for this auction is $' + self.budget;
				write '\t ' + myself.name + ' says: ' + self.name + ' likes ' + self.preferences;
			}
		}
		else if (cycle - initCycle = 100) {
			conversationRunning <- true;
			startConversation <- true;
		}
		
		if (cycle - initCycle = 99){
			pauseProgram <- true;
		}
		//CFP message is sent to all participants
		if ((priceAdjusted or startConversation) and !winnerDeclared) {
			stop <- false;
			if (length(namesOfParticipantsIgnoring) > nbOfParticipants) {
				namesOfParticipantsIgnoring <- [];
				numberOfParticipantsIgnoring <- 0;
			}
			do start_conversation with: [ to :: list(participant), protocol :: 'no-protocol', 
				performative :: 'inform', contents :: []
			];
			do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', 
				performative :: 'cfp', contents :: [itemPrice, itemType, agentColor] 
			];

			write name + ' (type: ' + itemType + ', color: ' + agentColor + 
				') sends a cfp message to all guests' color: agentColor;
			write 'The price of this item is $' + itemPrice color: agentColor;
		}
	}
	
	//Auctioneer receives propose messages from participants
	reflex receive_propose_messages when: !empty(proposes) {
		message proposeMessageReceived <- proposes[0];
		add all: proposes to: participantMessages; 
		write name + ' says: we have a winner! The winner is ' + proposeMessageReceived.sender + ' for a price of $' + itemPrice color: #orange ;
		do accept_proposal with: [ message :: proposeMessageReceived, contents :: [itemPrice]];
		
		loop p over: proposes {
			// write name + ' has rejected the proposal from ' + p.sender color: agentColor;
			do reject_proposal with: [ message :: p, contents :: [] ];
		}
	}
		
	//Auctioneer receives refuse messages from participants
	reflex receive_refuse_messages when: !empty(refuses) {
		add all: refuses to: participantMessages;
	}
	
	reflex updateReset when: numberOfParticipantsInformed = nbOfParticipants and
	 length(namesOfParticipantsIgnoring) = nbOfParticipants {
	 	ask participant {
	 		if (myself.name = self.auctioneerName){
	 			if cycle > self.interestedCycle {
					myself.resetAuction <- true;
	 			}
	 			else {
	 				myself.resetAuction <- false;
	 			}
	 		}
	 	}
	}
	
	/*
	 * System resets the auction process
	 */
	reflex resetAuction when: resetAuction and !winnerDeclared {
		cycleZero <- true;
		initCycle <- 0;
		//conversationRunning <- false;
		pauseProgram <- false;
		allRefused <- false;
		winnerDeclared <- false;
		resetAuction <- false;
		//namesOfParticipantsInformed <- [];
		//numberOfParticipantsInformed <- 0;
		numberOfParticipantsIgnoring <- 0;
		namesOfParticipantsIgnoring <- [];
		//numberOfParticipantsInterested <- 0;
		//namesOfParticipantsInterested <- [];

		loop p over: participantMessages {
			do end_conversation with: [ message :: p, contents :: [false] ];
		}
	}
	
	/*
	 * Auctioneer did not receive any proposals. Proceeds to adjust price and start bidding process again
	 */
	reflex adjustPrice when: conversationRunning and allRefused {
		if (itemPrice >= 0.5 * initialPrice) {
			write 'No one participated...so I will decrease the price a bit!' color: agentColor;
			itemPrice <- itemPrice * 0.9;
			priceAdjusted <- true;
			controlRefuses <- [];
			allRefused <- false;
		}
		else {
			write 'Oh come on!!! This was too big a bargain and none of you appreciated it. ' + 
			'This auction is now closed!' color: agentColor;
			priceAdjusted <- false;
			resetAuction <- true;
			write 'Previous auctioneer has left the scene.';
			write 'New auctioneer enters the scene and starts preparing the auction';
			winnerDeclared <- true;
			ask participant {
				if (myself.name = self.auctioneerName) {
					self.alreadyInAuction <- false;
					self.agentColor <- nil;
				}
			}
		}
	}
	
	reflex dieWhenWinner when: winnerDeclared {
		write 'Previous auctioneer has left the scene.';
		write 'New auctioneer enters the scene and starts preparing the auction';
		create initiator number: 1 {}
		do die;
	}
}

species participant skills: [fipa, moving]{
	
	float budget;
	rgb agentColor;
	string auctioneerName;
	point auctioneerLocation;
	image_file icon;
	point targetPoint;
	bool alreadyInAuction;
	list<string> preferences;
	int interestedCycle;

	
	init {
		budget <- float(rnd(2000, 3000));
		add auctionTypes[rnd(length(auctionTypes) - 1)] to: preferences;
	}
	
	aspect default {
			draw icon size: 6;
			draw sphere(1.5) at: location color: agentColor;
	}
	
	// Participants move while an auction is NOT in place
	reflex beIdle when: empty(cfps) {
		do wander speed: 0.25;
	}
	
	reflex moveToTarget when: alreadyInAuction{
		do goto target:targetPoint speed: 500.0;
	}
	
	// Participants receive CFP messages
	reflex receive_cfp_from_initiator when: !empty(cfps) and !stop {
		int cfpsIndex <- 0;
		string senderName;
		loop while: cfpsIndex < length(cfps) {
			message proposalFromInitiator <- cfps[cfpsIndex];
			let senderInitiator <- initiator(proposalFromInitiator.sender);
			
			if (!dead(senderInitiator)) {
				senderName <- agent(proposalFromInitiator.sender).name;
				if (!alreadyInAuction or senderInitiator.namesOfParticipantsInterested contains name) {
					if (not(senderInitiator.namesOfParticipantsInformed contains name)) {
						senderInitiator.numberOfParticipantsInformed <- senderInitiator.numberOfParticipantsInformed + 1;
						add name to: senderInitiator.namesOfParticipantsInformed;
					}
					
					if (preferences contains proposalFromInitiator.contents[1]) {
						auctioneerName <- senderName;
						auctioneerLocation <- agent(proposalFromInitiator.sender).location;
						agentColor <- proposalFromInitiator.contents[2];
						alreadyInAuction <- true;
						targetPoint <- {auctioneerLocation.x - 5, auctioneerLocation.y + 5};
						
						if (not(senderInitiator.namesOfParticipantsInterested contains name)) {
							senderInitiator.numberOfParticipantsInterested <- senderInitiator.numberOfParticipantsInterested + 1;
							add name to: senderInitiator.namesOfParticipantsInterested;
						}
						
						if (length(senderInitiator.namesOfParticipantsInformed) = nbOfParticipants) {
							// Participant checks his budget and sends his proposal
							interestedCycle <- cycle;
							if (budget - float(proposalFromInitiator.contents[0]) > 0.05 * budget){
								write 'Hey ' + senderName + ', my name is ' + name + ' and I want to buy!' color: #green ;
								write '(My current budget is $' + budget + ' so I should be ok)' color: #green;
								do propose with: [ message :: proposalFromInitiator, contents :: [true] ];							
							}
							// Participant declines because he does not have a high enough budget
							else {
								ask initiator {
									if (self.name = senderName) {
										if (not(controlRefuses contains myself.name)) {
											write 'Hey ' + senderName + ', my name is ' + myself.name + ' and I think it\'s too expensive!' color: #red ;
											write '(My current budget is $' + myself.budget + ' so I cannnot afford it!)' color: #red ;
											do refuse with: [ message :: proposalFromInitiator, contents :: [false] ];
											add myself.name to: self.controlRefuses;
										}
										if (length(self.controlRefuses) = length(self.namesOfParticipantsInterested)) {
											allRefused <- true;
										}
									}
								}
							}
						}
					}
					else {
						ask initiator {
							if (self.name = senderName) {
								if (!(namesOfParticipantsIgnoring contains myself.name)) {
									self.numberOfParticipantsIgnoring <- self.numberOfParticipantsIgnoring + 1;
									add myself.name to: namesOfParticipantsIgnoring;
								}
								if (length(namesOfParticipantsIgnoring) = nbOfParticipants) {
									self.resetAuction <- true;
								}
							}
						}
					}
				}
			}
			cfpsIndex <- cfpsIndex + 1;	
		}
	}
	
	/*
	 * Participant receives the accept proposal and adjusts his budget. He then sends his inform message. 
	 */
	reflex receive_accept_proposals when: !empty(accept_proposals) and !stop {
		message acceptProposalFromInitiator <- accept_proposals[0];
		if (!dead(initiator(acceptProposalFromInitiator.sender))) {
			write name + ' receives an accept_proposal message from ' + agent(acceptProposalFromInitiator.sender).name;
			budget <- budget - float(acceptProposalFromInitiator.contents[0]);
			write name + ' has adjusted his remaining budget. It is now: $' + budget;
			write 'This auction is now closed!'color: #red ;
			
			alreadyInAuction <- false;
			agentColor <- nil;
			ask initiator {
				if (myself.auctioneerName = self.name){
					self.winnerDeclared <- true;
					stop <- true;
				}
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
