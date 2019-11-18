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
	participant refuser;
	list<participant> proposers;
	participant reject_proposal_participant;
	list<participant> accept_proposal_participants ;
	participant failure_participant;
	participant inform_done_participant;
	participant inform_result_participant;
	bool pauseProgram;
	bool proposalExists;
	bool resetAuction;
	
	init {
		create initiator number: 1 {}
		create participant number: nbOfParticipants returns: ps {}
	}
	
	reflex pauseSimulation when: pauseProgram {
		do pause;
	}
}

species initiator skills: [fipa] {
	
	rgb agentColor;
	image_file icon;
	bool cycleZero;
	float itemPrice;
	int initCycle;
	list<message> participantMessages;
		
	
	init {
		write 'me inicio pedazo de caca';
		agentColor <- #gray;
		//icon <- image_file("../includes/img/EricCartman.png");
		cycleZero <- true;
	}
	
	aspect default {
			draw icon size: 6;
			draw sphere(1.5) at: location color: agentColor;
	}
	
	//Auctioneer appears every set amount of cycles
	reflex initiatorAppear {
		int appearCycle;
		write 'funcione wn ' + cfps;
		//conversationRunning <- false;
		if cycleZero {
			initCycle <- cycle;
			cycleZero <- false;
			write 'AHHHHHHHHHHHHHHHHHHHHHHHH initCycle is ' + initCycle;
			write 'EHHHHHHHHHHHHHHHHHHHHHH cycle is ' + cycle;
			resetAuction <- false;
			pauseProgram <- false;
		}
		//CFP message is sent to all participants
		else if (cycle - initCycle = 2500) {
			agentColor <- #purple;
			itemPrice <- float(rnd(1000, 3000));
			write name + ' sends a cfp message to all guests';
			write 'The price of this item is $' + itemPrice;
			conversationRunning <- true;
			do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [itemPrice]];
			write 'MOFO????? aja pez ' + cfps;
		}
		//write '/////////////////////initCycle is ' + initCycle;
		//write '----------------cycle is ' + cycle;		
	}
	
	//Auctioneer receives propose messages from participants
	reflex receive_propose_messages when: !empty(proposes) {
		message proposeMessageReceived <- proposes[0];
		add all: proposes to: participantMessages; 
		write 'We have a winner! The winner is ' + proposeMessageReceived.sender + 'for a price of $' + itemPrice;
		do accept_proposal with: [ message :: proposeMessageReceived, contents :: [itemPrice]];

		loop p over: proposes {
			write name + ' has rejected the proposal from ' + p.sender;
			do reject_proposal with: [ message :: p, contents :: [] ];
		}
	}
		
	//Auctioneer receives refuse messages from participants
	reflex receive_refuse_messages when: !empty(refuse) {
		add all: refuses to: participantMessages;
	}
	
	/*
	 * Auctioneer receives inform message from participant and ends the auction
	 */
	reflex resetAuction when: resetAuction {
		cycleZero <- true;
		initCycle <- 0;
		conversationRunning <- false;
		
		loop p over: participantMessages {
			write name + ' is finishing conversation with ' + p.sender;
			do end_conversation with: [ message :: p, contents :: [false] ];
		}
		
		write name + ' has ended the auction!';
		pauseProgram <- true;
	}
	
	/*
	 * Auctioneer did not receive any proposals. Proceeds to adjust price and start bidding process again
	 */
	reflex adjustPrice when: length(refuse) = nbOfParticipants {
		write name + ' says the bid has been refused by everyone. It will proceed to adjust the price';
		itemPrice <- itemPrice * 0.9;
		resetAuction <- true;
	}
}

species participant skills: [fipa] {
	
	float budget;
	rgb agentColor;
	image_file icon;
	
	init {
		budget <- float(rnd(1500, 5000));
		write 'The budget of ' + name + ' is ' + budget;
	}
	
	aspect default {
			draw icon size: 6;
			draw sphere(1.5) at: location color: agentColor;
	}
	
	
	//Participants receive CFP messages
	reflex receive_cfp_from_initiator when: conversationRunning and !empty(cfps) {
		write 'CFPS ' + cfps;
		message proposalFromInitiator <- cfps[0];
		write name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ' with item Price = $' + proposalFromInitiator.contents + '.00';
		
		//Participant checks his budget and sends his proposal
		write 'Contents es ' + proposalFromInitiator.contents[0];		
		if (budget - float(proposalFromInitiator.contents[0]) > 0.05 * budget){
			//write '\t' + name + ' sends a propose message to ' + agent(proposalFromInitiator.sender).name;
			write '\t My name is ' + name + ' and I want to buy!';
			do propose with: [ message :: proposalFromInitiator, contents :: [true] ];
		}
		//Participant declines because he does not have a high enough budget
		else{
			write '\t My name is ' + name + ' and I think it\'s too expensive!';
			do refuse with: [ message :: proposalFromInitiator, contents :: [false] ];
		} 
	}
	
	/*
	 * Participant receives the accept proposal and adjusts his budget. He then sends his inform message. 
	 */
	reflex receive_accept_proposals when: conversationRunning and !empty(accept_proposals) {
		message acceptProposalFromInitiator <- accept_proposals[0];
		write name + ' receives an accept_proposal message from ' + agent(acceptProposalFromInitiator.sender).name;
		write name + ' has a budget of  ' + budget;
		budget <- budget - float(acceptProposalFromInitiator.contents[0]);
		write name + ' has adjusted his remaining budget. It is now: $' + budget;
		resetAuction <- true;
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