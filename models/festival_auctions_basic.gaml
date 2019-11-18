/***
* Name: festival_auctions_basic
* Author: Jhorman A. Pérez B. and Wilfredo J. Robinson M. 
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model festival_auctions_basic

/* Insert your model definition here */
global {
	
	int nbOfParticipants <- 10;
	participant refuser;
	list<participant> proposers;
	participant reject_proposal_participant;
	list<participant> accept_proposal_participants ;
	participant failure_participant;
	participant inform_done_participant;
	participant inform_result_participant;
	bool pauseProgram;
	
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
	int itemPrice;
	
	
	init {
		agentColor <- #gray;
		icon <- image_file("../includes/img/EricCartman.png") ;
		cycleZero <- true;
	}
	
	aspect default {
			draw icon size: 6;
			draw sphere(1.5) at: location color: agentColor;
	}
	
	reflex initiatorAppear {
		int initCycle;
		int appearCycle;
		
		if cycleZero {
			initCycle <- cycle;
			cycleZero <- false;	
		}
		else if (cycle - initCycle = 2500) {
			agentColor <- #purple;
			itemPrice <- rnd(1000, 3000);
			write name + ' sends a cfp message to all guests';
			write 'The price of this item is ' + itemPrice;
			do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: [itemPrice]];
		}		
	}
	
	
	
	
	reflex send_cfp_to_participants when: (time = 1) {
		
		write '(Time ' + time + '): ' + name + ' sends a cfp message to all guests';
		do start_conversation with: [ to :: list(participant), protocol :: 'fipa-contract-net', performative :: 'cfp', contents :: ['Go swimming'] ];
	}
	
	reflex receive_refuse_messages when: !empty(refuses) {
		loop r over: refuses {
			write '\t' + name + ' receives a refuse message from ' + agent(r.sender).name;
		}
	}
	
	reflex receive_propose_messages when: !empty(proposes) {
		
		do accept_proposal with: [ message :: proposes[0], contents :: [itemPrice]];
		write 'Got it! The winner is ' + proposes[0].sender + 'for a price of ' + itemPrice;	
		remove first(proposes) from: proposes;
		
		loop p over: proposes {
			//write '\t' + name + ' receives a propose message from ' + agent(p.sender).name;
			do reject_proposal with: [ message :: p, contents :: ['Try again next time!'] ];
		}
	}
	
	reflex receive_failure_messages when: !empty(failures) {
		message f <- failures[0];
		write '\t' + name + ' receives a failure message from ' + agent(f.sender).name + ' with content ' + f.contents ;
	}
	
	reflex receive_inform_messages when: !empty(informs) {
		write '(Time ' + time + '): ' + name + ' receives inform messages';
		
		loop i over: informs {
			write '\t' + name + ' receives a inform message from ' + agent(i.sender).name + ' with content ' + i.contents ;
		}
	}
}

species participant skills: [fipa] {
	
	int budget;
	
	
	init {
		budget <- rnd(1500, 5000);
	}
	
	reflex receive_cfp_from_initiator when: !empty(cfps) {
		pauseProgram <- true;
		message proposalFromInitiator <- cfps[0];
		write name + ' receives a cfp message from ' + agent(proposalFromInitiator.sender).name + ' with item Price = ' + proposalFromInitiator.contents;
		
		if (budget - int(proposalFromInitiator.contents) > 0.05 * budget){
			//write '\t' + name + ' sends a propose message to ' + agent(proposalFromInitiator.sender).name;
			write '\t My name is ' + name + ' and I\'m in!';
			do propose with: [ message :: proposalFromInitiator, contents :: [true] ];
		}
		else{
			write '\t My name is ' + name + ' and I think it\'s too expensive!';
			do refuse with: [ message :: proposalFromInitiator, contents :: [false] ];
		} 
		
		
		
		
		if (self = refuser) {
			write '\t' + name + ' sends a refuse message to ' + agent(proposalFromInitiator.sender).name;
			do refuse with: [ message :: proposalFromInitiator, contents :: ['I am busy today'] ];
		}
		
		if (self in proposers) {
			write '\t' + name + ' sends a propose message to ' + agent(proposalFromInitiator.sender).name;
			do propose with: [ message :: proposalFromInitiator, contents :: ['Ok. That sound interesting'] ];
		}
	}
	
	reflex receive_reject_proposals when: !empty(reject_proposals) {
		message r <- reject_proposals[0];
		write '(Time ' + time + '): ' + name + ' receives a reject_proposal message from ' + agent(r.sender).name + ' with content ' + r.contents;
	}
	
	reflex receive_accept_proposals when: !empty(accept_proposals) {
		message a <- accept_proposals[0];
		write name + ' receives an accept_proposal message from ' + agent(a.sender).name;
		budget <- budget - int(a.contents);
		
		
		if (self = failure_participant) {
			write '\t' + name + ' sends a failure message to ' + agent(a.sender).name;
			do failure with: [ message :: a, contents :: ['Failure'] ];
		}
		
		if (self = inform_done_participant) {
			write '\t' + name + ' sends an inform_done message to ' + agent(a.sender).name;
			do inform with: [ message :: a, contents :: ['Inform done'] ];
		}
		
		if (self = inform_result_participant) {
			write '\t' + name + ' sends an inform_result message to ' + agent(a.sender).name;
			do inform with: [ message :: a, contents :: ['Inform result'] ];
		}
	}
}

experiment test type: gui {
	output {
		
	}
}
