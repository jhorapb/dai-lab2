/***
* Name: festival_auctions_basic
* Author: Jhorman A. Pérez B. and Wilfredo J. Robinson M. 
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model festival_auctions_basic

/* Insert your model definition here */
global {
	
	bool conversationRunning;
	int nbOfParticipants <- 3;
	list<participant> proposers;
	list<participant> accept_proposal_participants;
	bool pauseProgram;
	bool resetAuction;
	bool initiatorCreated <- true;
	bool priceAdjusted;
	bool startConversation;
	list<int> controlRefuses <- [];
	bool allRefused;
	
	
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
	float initialPrice;
	point targetPoint;
	int adjustCycle;
	
	init {
		agentColor <- #purple;
		//icon <- image_file("../includes/img/EricCartman.png");
		cycleZero <- true;
	}
	
	aspect default {
			draw icon size: 6;
			draw sphere(1.5) at: location color: agentColor;
	}
	
	//Participants move while an auction is NOT in place
	reflex beIdle when: empty(cfps) {
		do wander speed: speed;
	}
	
	//Auctioneer appears every set amount of cycles
	reflex initiatorAppear {
		if cycleZero {
			initCycle <- cycle;
			cycleZero <- false;
			resetAuction <- false;
			pauseProgram <- false;
			itemPrice <- float(rnd(1000, 3000));
			initialPrice <- itemPrice;
			ask participant {
				write 'The initial budget of ' + name + ' is $' + budget;
			}
		}
		//CFP message is sent to all participants
		else if (cycle - initCycle = 10000) {
			conversationRunning <- true;
			startConversation <- true;
		}
		
		if (cycle - initCycle = 9999){
			pauseProgram <- true;
		}
		if (priceAdjusted or startConversation) and !allRefused {
			allRefused <- false;
			controlRefuses <- [];
			do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [itemPrice]];
			write 'Auctioneer sends a cfp message to all guests';
			write 'The price of this item is $' + itemPrice color: #purple ;
		}
	}
	
	//Auctioneer receives propose messages from participants
	reflex receive_propose_messages when: !empty(proposes) {
		message proposeMessageReceived <- proposes[0];
		add all: proposes to: participantMessages; 
		write 'We have a winner! The winner is ' + proposeMessageReceived.sender + 'for a price of $' + itemPrice color: #orange ;
		do accept_proposal with: [ message :: proposeMessageReceived, contents :: [itemPrice]];
		
		loop p over: proposes {
			write 'Auctioneer has rejected the proposal from ' + p.sender color: #purple ;
			do reject_proposal with: [ message :: p, contents :: [] ];
		}
	}
		
	//Auctioneer receives refuse messages from participants
	reflex receive_refuse_messages when: !empty(refuses) {
		//controlRefuses <- [];
		add all: refuses to: participantMessages;
	}
	
	/*
	 * System resets the auction process
	 */
	reflex resetAuction when: resetAuction {
		cycleZero <- true;
		initCycle <- 0;
		conversationRunning <- false;
		pauseProgram <- false;
		allRefused <- false;
		
		loop p over: participantMessages {
			do end_conversation with: [ message :: p, contents :: [false] ];
		}
	}
	
	/*
	 * Auctioneer did not receive any proposals. Proceeds to adjust price and start bidding process again
	 */
	reflex adjustPrice when: allRefused {
		if (itemPrice >= 0.5 * initialPrice) {
			write 'No one participated...so I will decrease the price a bit!' color: #purple;
			itemPrice <- itemPrice * 0.9;
			priceAdjusted <- true;
			controlRefuses <- [];
			allRefused <- false;	
		}
		else {
			write 'Oh come on!!! This was too big a bargain and none of you appreciated it. This auction is now closed!' color: #purple;
			priceAdjusted <- false;
			resetAuction <- true;
			initiatorCreated <- false;
		}
	}
}

species participant skills: [fipa, moving]{
	
	float budget;
	rgb agentColor;
	image_file icon;
	point targetPoint;

	
	init {
		budget <- float(rnd(1500, 1600));
	}
	
	aspect default {
			draw icon size: 6;
			draw sphere(1.5) at: location color: agentColor;
	}
	
	//Auctioneers move while an auction is NOT in place
	reflex beIdle when: empty(cfps) {
		do wander speed: speed;
	}
	
	
	//Participants receive CFP messages
	reflex receive_cfp_from_initiator when: conversationRunning and !empty(cfps) {
		message proposalFromInitiator <- cfps[0];
		
		//Participant checks his budget and sends his proposal
		if (budget - float(proposalFromInitiator.contents[0]) > 0.05 * budget){
			write '\t My name is ' + name + ' and I want to buy!' color: #green ;
			write '(My current budget is $' + budget + ' so I should be ok)' color: #green;
			do propose with: [ message :: proposalFromInitiator, contents :: [true] ];
		}
		//Participant declines because he does not have a high enough budget
		else{
			write '\t My name is ' + name + ' and I think it\'s too expensive!' color: #red ;
			write '(My current budget is $' + budget + ' so I cannnot afford it!)' color: #red ;
			do refuse with: [ message :: proposalFromInitiator, contents :: [false] ];
			add 1 to: controlRefuses;
			if (length(controlRefuses) = nbOfParticipants){
				allRefused <- true;
			}
		}
		startConversation <- false;
	}
	
	/*
	 * Participant receives the accept proposal and adjusts his budget. He then sends his inform message. 
	 */
	reflex receive_accept_proposals when: conversationRunning and !empty(accept_proposals) {
		message acceptProposalFromInitiator <- accept_proposals[0];
		write name + ' receives an accept_proposal message from ' + agent(acceptProposalFromInitiator.sender).name;
		budget <- budget - float(acceptProposalFromInitiator.contents[0]);
		write name + ' has adjusted his remaining budget. It is now: $' + budget;
		write 'This auction is now closed!'color: #red ;
		priceAdjusted <- false;
		resetAuction <- true;
		initiatorCreated <- false;
	}
	
	/*
	 * Create a new initiator once an auction ends
	 */
	reflex create_new_initiator when: resetAuction and !initiatorCreated {
		ask initiator {
			do die;
		}
		write 'Previous auctioneer has left the scene.';
		create initiator number: 1 {}
		write 'New auctioneer enters the scene and starts preparing the auction';
		initiatorCreated <- true;
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