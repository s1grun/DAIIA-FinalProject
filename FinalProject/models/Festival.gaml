/***
* Name: Festival
* Author: sigrunarnasigurdardottir
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Festival

/* Insert your model definition here */
global {

    list<string> genre <- ["rock", "pop", "folks", "jazz"];
    list<string> guestTypes <- ["chill", "party", "tired", "drunk", "journalist"];
    list<Guests> tiredList <-[];
    list<Guests> partyList <-[];
    list<Guests> chillList <-[];
    list<Guests> drunkList <-[];
    list<Guests> journalistList <-[];
    
	init {	
		
		point storeLocation1 <- {25, 25};
		create Guests number: 70;

		loop gu over:Guests{
			if(gu.gType="tired"){
				add gu to:tiredList;
			}else if(gu.gType="party"){
				add gu to:partyList;
			}else if(gu.gType = "chill"){
				add gu to:chillList;
			}else if(gu.gType="drunk"){
				add gu to:drunkList;
			}else if(gu.gType="journalist"){
				add gu to:journalistList;
			}
		}
		

		create Venue number: 2 with:(stage_color:#blue,type:"bar");
		
		create Venue number: 1 with:(stage_color:#yellow,type:"party");
		
		create Venue number: 1 with:(stage_color:#green,type:"concert");
	
	}
	
	
}

species Guests skills:[moving, fipa]{	
	float popMusic <- rnd(0.0, 1.0);
	float rockMusic <- rnd(0.0, 1.0);
	float folksMusic <- rnd(0.0, 1.0);
	float jazzMusic <- rnd(0.0, 1.0);
	point guestLocation <- nil;
	rgb my_color <- #blue;
	string gType <- guestTypes[rnd(length(guestTypes) - 1)];
	Venue dest <-nil;
	list stage_list<-[];
	int movingStatus <- 0; // 0-> do wander,1-> go to stage,2-> at stage;
	int interaction <-0; //0->no interaction, 1->interact with someone.
	float generous <- rnd(0.0,1.0);
	Guests friend <- nil;
	float happy <- rnd(0.0,0.5);
	float sleepy <- rnd(0.0,0.5);
	float angry <- rnd(0.0,0.5);
	float partyMood <- rnd(0.0,0.5);
	
	
	init{
		guestLocation<-location;
		if(gType="tired"){
			sleepy <- 0.5;
		}
		
	}
	
	aspect default {

		if(gType="drunk"){
			draw circle(2) color:#red;
		}else if(gType="party"){
			draw circle(2) color:#yellow;
		}else if(gType="chill"){
			draw circle(2) color:#green;
		}else if(gType="tired"){
			draw circle(2) color:#gray;
		}else if(gType="journalist"){
			draw circle(2) color:#blue;
		}
		
	}
	
	reflex reset {
		if(happy>2){
			happy<- 1.0;
		}else if(happy < 0){
			happy<- 0.3;
		}
		
		if(sleepy >2 ){
			sleepy<- 1.0;
		}else if(sleepy < -1 ){
			sleepy<- 0.3;
		}
		if(angry > 2){
			angry<- 1.0;
		}else if(angry < -1){
			angry<- 0.3;
		}
		if(generous > 2){
			generous<- 1.0;
		}else if(generous < -1){
			generous<- 0.3;
		}
	}


//In this reflex method we receive all inform fipa message and handle them depending on the content
	reflex getInfo when:!(empty(informs)){
		loop msg over: informs{
			Venue spot<- Venue(agent(msg.sender));
			if(msg.contents[0]="start"){ //If the content is start we add the location of the venue to our list
				add spot to:stage_list;
				if(flip(0.5)){
					if(friend != nil and spot.type="concert"){//If the venue type is concert we send our friend a messasge to invite to the concert
						write name + " sending invite to friend " + friend;
						do start_conversation with: [to :: list(friend), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['invitation',spot] ];
						dest<- spot;
						movingStatus <-1;	
					}else{
						dest<- spot;
						movingStatus <-1;
					}
				}

			}else if(msg.contents[0]="end"){//if the content is end we remove the venue location from our list
				
				if(dest!=nil){
					if(dest=spot){
						if(length(stage_list)>1){
							remove spot from:stage_list;
							dest<- stage_list[rnd(length(stage_list) - 1)];
						
							movingStatus <-1;
						}
						
					}
				}
			}else if (msg.contents[0]="invitation"){//If a friend receives a invitation to a concert he will add the location of the concert to the list and go to the concert
				spot<-msg.contents[1];
				add spot to:stage_list;							
				dest<- spot;
				movingStatus <-1;
				write name +" going to concert with friend " + agent(msg.sender);
			}
		}
			
	}
	
	reflex goToStage when:movingStatus=1{//Here we go to our selected destination
		do goto target:dest;
		
	}
	
	reflex nearStage when: dest!=nil and distance_to(self,dest)<=7 and movingStatus=1{
		movingStatus <- 2;
		if(friend != nil){
			ask friend {//After friends have been together at a venue they will unfriend each other to make new friends
				if(self.friend != nil){
					write name + "is no longer friend with " + self.friend;
					myself.friend <- nil;
					self.friend <- nil;
				}
			}
		}
	}
	
	
	reflex atStage when: movingStatus=2 and friend=nil{//When the guests are at a venue and don't have a friend they can make a new friend
		do wander;
		
		interaction <-0;
		if(gType="drunk"){
			ask Guests at_distance 3{
					if(self.gType="drunk"){
						if(flip(0.9)){
							myself.friend<- self;
							self.friend<- myself;
						}
					}else if(self.gType="journalist"){
						if(flip(0.3)){
							myself.friend<- self;
							self.friend<- myself;
						}
					}else{
						if(self.happy>=0.5){
							myself.friend<- self;
							self.friend<- myself;
						}
						
					}
					
				}
		}else if(gType="party"){
			if(dest.type="party"){
				ask Guests at_distance 3{
					if(self.gType="tired"){
						if(sleepy<=0.7 and flip(0.3)){
							myself.friend<- self;
							self.friend<- myself;
						}
					}else{
						if(flip(0.7)){
							myself.friend<- self;
							self.friend<- myself;
						}
					}
				}
			}else{
				ask Guests at_distance 3{
					if(flip(0.3)){
							myself.friend<- self;
							self.friend<- myself;
					}
				}
			}
		}else if(gType="chill"){
			ask Guests at_distance 3{
				if(self.gType="tired"){
					if(sleepy<=0.7 and flip(0.5)){
						myself.friend<- self;
						self.friend<- myself;
					}
				}else{
					if(flip(0.7)){
						myself.friend<- self;
						self.friend<- myself;
					}
				}
			}

			
		}else if(gType="tired"){
		
			if(length(Guests at_distance 3)>10 or sleepy>0.7){
				write name+" tired guy leave the "+dest.type;
				dest<- stage_list[rnd(length(stage_list) - 1)];
				movingStatus <-1;
			}else{
				ask Guests at_distance 3{
					if(self.gType!="tired"){
						myself.friend<- self;
						self.friend<- myself;
					}
				}
			}
			
			
		}else if(gType="journalist"){
			ask Guests at_distance 3{
				if(self.gType!="tired"){
					if(flip(0.3) and sleepy<=0.7){
						myself.friend<- self;
						self.friend<- myself;
					}
				}else{
					if(flip(0.5)){
						myself.friend<- self;
						self.friend<- myself;
					}
				}
			}
		}

	}
	
	reflex withFriend when: movingStatus=2 and friend!=nil and interaction=0 {//When guests are with they're friends we have rules of interaction depending on their personal traits
		
		ask friend {
			
		
		if(myself.gType="drunk"){//When a drunk guest meets a friend and depending how he's feeling and on the type of guest his friend is. 
			if(myself.dest.type="concert"){
				myself.sleepy <- myself.sleepy+0.5;
				myself.happy <- myself.happy-0.4;
				myself.angry <- myself.angry+0.1;
				myself.generous <- myself.generous-0.1;
				self.sleepy <- self.sleepy+0.1;
				self.happy <- self.happy-0.2;
				self.angry <- self.angry+0.2;
				self.generous <- self.generous-0.1;
				myself.friend <- nil;
			}else{
				if(self.gType="party" or self.gType="chill"){
					if(myself.generous > 0.25 and myself.angry < 0.5){
						write myself.gType + " is feeling generous and buys " + self.gType + " a drink";
						if(self.happy >= 0.2 and self.angry < 0.2){
							write self.gType + "Is feeling happy and accepts a drink from " + myself.gType;
							myself.happy <- myself.happy+0.2;
							myself.angry <- myself.angry-0.2;
							myself.generous <- myself.generous+0.2;
							myself.sleepy <- myself.sleepy+0.1;
							self.happy <- self.happy+0.1;
							self.angry <- self.angry-0.2;
							self.generous <- self.generous+0.2;
							self.sleepy <- self.sleepy+0.1;
						}else{
							write self.gType+ " does not want to have a drink with " + myself.gType;
							myself.happy <- myself.happy-0.2;
							myself.angry <- myself.angry+0.2;
							myself.generous <- myself.generous-0.2;
							myself.sleepy <- myself.sleepy-0.1;
							self.happy <- self.happy-0.1;
							self.angry <- self.angry+0.2;
							self.generous <- self.generous-0.2;
							self.sleepy <- self.sleepy-0.1;
						}

					}
					else if(myself.angry > 0.2 and myself.generous < 0.2){
						write myself.gType + " is feeling angry when he meets " + self.gType;
						myself.happy <- myself.happy-0.3;
						myself.angry <- myself.angry+0.3;
						myself.generous <- myself.generous-0.2;
						myself.sleepy <- myself.sleepy+0.2;
						self.angry <- self.angry+0.5;
						self.happy <- self.happy-0.2;
						self.generous <- self.generous-0.2;
						self.sleepy <- self.sleepy+0.2;
					}
					else if(myself.happy > 0.2){
						write myself.gType + " is feeling happy and chats with " + self.gType;
						myself.happy <- myself.happy+0.2;
						myself.angry <- myself.angry-0.3;
						myself.generous <- myself.generous+0.1;
						myself.sleepy <- myself.sleepy-0.2;
						self.happy <- self.happy+0.1;
						self.angry <- self.angry-0.3;
						self.generous <- self.generous+0.1;
						self.sleepy <- self.sleepy-0.2;
					}
			}else if(self.gType="tired"){
				if(myself.sleepy < 0.7 and myself.happy > 0.3){
						write myself.gType + " is hanging out with another " + self.gType;
						myself.sleepy <- myself.sleepy+0.4;
						myself.happy <- myself.happy+0.3;
						myself.angry <- myself.angry-0.3;
						myself.generous <- myself.generous+0.1;
						self.sleepy <- self.sleepy+0.4;
						self.happy <- self.happy+0.3;
						self.angry <- self.angry-0.3;
						self.generous <- self.generous+0.1;
					}
					else if(self.sleepy >= 0.7){
						write myself.gType + " is angry and unfriends " + self.gType;
						myself.sleepy <- myself.sleepy+0.5;
						myself.happy <- myself.happy-0.4;
						myself.angry <- myself.angry+0.4;
						myself.generous <- myself.generous-0.1;
						self.sleepy <- self.sleepy+0.5;
						self.happy <- self.happy-0.4;
						self.angry <- self.angry+0.4;
						self.generous <- self.generous-0.1;
						myself.friend <- nil;
					}
			}
			}
			
		}else if(myself.gType="party"){
//			if(friend.gType){
			if(myself.dest.type="party"){
				if(myself.sleepy<0.9 and self.sleepy<0.5){
					write myself.gType + " is happy with his friend " + self.gType+" at party";
					myself.angry <- myself.angry-0.3;
					myself.happy <- myself.happy+0.2;
					myself.generous <- myself.generous+0.2;
					myself.sleepy <- myself.sleepy-0.1;
					self.angry <- self.angry-0.3;
					self.happy <- self.happy+0.2;
					self.generous <- self.generous+0.2;
					self.sleepy <- self.sleepy-0.1;
				}else{
					write myself.gType + " is feeling sleepy and says goodbye to his friend " + self.gType;
					myself.happy <- myself.happy-0.1;
					myself.angry <- myself.angry+0.1;
					myself.generous <- myself.generous-0.1;
					myself.sleepy <- myself.sleepy+0.2;
					self.happy <- self.happy-0.1;
					self.angry <- self.angry+0.1;
					self.generous <- self.generous-0.1;
					self.sleepy <- self.sleepy+0.1;
					myself.friend <- nil;
					do wander; 
				}
				
			}else{
				if(myself.angry > 0.2 and myself.happy < 0.2 and myself.sleepy < 0.5){
					write myself.gType + " is angry and does not want to hangout with his friend " + self.gType;
					myself.angry <- myself.angry+0.2;
					myself.happy <- myself.happy-0.2;
					myself.generous <- myself.generous-0.2;
					myself.sleepy <- myself.sleepy+0.1;
					self.angry <- self.angry+0.2;
					self.happy <- self.happy-0.2;
					self.generous <- self.generous-0.2;	
					self.sleepy <- self.sleepy+0.1; 
				} 
				else if(myself.happy > 0.2 and myself.sleepy < 0.5) {
					write myself.gType + " is happy with his friend " + self.gType;
					myself.angry <- myself.angry-0.3;
					myself.happy <- myself.happy+0.2;
					myself.generous <- myself.generous+0.2;
					myself.sleepy <- myself.sleepy-0.1;
					self.angry <- self.angry-0.3;
					self.happy <- self.happy+0.2;
					self.generous <- self.generous+0.2;
					self.sleepy <- self.sleepy-0.1;
					
				} 
				else if(myself.sleepy > 0.5){
					write myself.gType + " is feeling sleepy and says goodbye to his friend " + self.gType;
					myself.happy <- myself.happy-0.1;
					myself.angry <- myself.angry+0.1;
					myself.generous <- myself.generous+0.1;
					myself.sleepy <- myself.sleepy+0.2;
					self.happy <- self.happy-0.1;
					self.angry <- self.angry+0.1;
					self.generous <- self.generous-0.1;
					self.sleepy <- self.sleepy-0.1;
					myself.friend <- nil;
					do wander; 
				}
			}
				
		}else if(myself.gType="chill"){
			if(self.gType="journalist"){
					if(myself.sleepy > 0.5){
						write myself.gType + " is feeling too tired to be interviewd by " + self.gType;
						myself.happy <- myself.happy-0.2;
						myself.angry <- myself.angry-0.3;
						myself.generous <- myself.generous-0.1;
						myself.sleepy <- myself.sleepy+0.3;
						self.happy <- self.happy-0.2;
						self.angry <- self.angry+0.3;
						self.generous <- self.generous-0.1;
						self.sleepy <- self.sleepy-0.1;
					}
					else if(myself.happy > 0.5 and myself.generous < 0.5){
						write myself.gType + " is feeling happy and is interviewed by " + self.gType;
						myself.happy <- myself.happy+0.2;
						myself.angry <- myself.angry-0.3;
						myself.generous <- myself.generous+0.1;
						myself.sleepy <- myself.sleepy-0.1;
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.3;
						self.generous <- self.generous+0.1;
						self.sleepy <- self.sleepy-0.1;
					}
					else if(myself.angry > 0.7 and myself.generous < 0.2){
							write myself.gType + " is feeling angry and does not want to be interviewed by " + self.gType;
							myself.happy <- myself.happy-0.2;
							myself.angry <- myself.angry+0.2;
							myself.generous <- myself.generous-0.1;
							myself.sleepy <- myself.sleepy+0.1;
							self.happy <- self.happy-0.2;
							self.angry <- self.angry+0.3;
							self.generous <- self.generous-0.1;
							self.sleepy <- self.sleepy+0.1;
						}
					else if(myself.generous > 0.5){
							write myself.gType + " is feeling generous and is interviewed by " + self.gType;
							myself.happy <- myself.happy+0.2;
							myself.angry <- myself.angry-0.2;
							myself.generous <- myself.generous+0.3;
							myself.sleepy <- myself.sleepy-0.1;
							self.happy <- self.happy+0.2;
							self.angry <- self.angry-0.3;
							self.generous <- self.generous+0.1;
							self.sleepy <- self.sleepy-0.1;
						
						}
				}else if(self.gType="party" or self.gType="drunk"){
					if(myself.happy > 0.5 and myself.angry < 0.7 and myself.generous < 0.5){
						write myself.gType + " is feeling happy and chills with " + self.gType;
						myself.happy <- myself.happy+0.2;
						myself.angry <- myself.angry-0.3;
						myself.generous <- myself.generous+0.1;
						myself.sleepy <- myself.sleepy-0.1;
						self.happy <- self.happy+0.1;
						self.angry <- self.angry-0.3;
						self.generous <- self.generous+0.1;
						self.sleepy <- self.sleepy-0.1;
					}
					else if(myself.angry > 0.7 and myself.generous < 0.5){
						write myself.gType + " is feeling angry and does not want to chill with " + self.gType;
						myself.happy <- myself.happy-0.2;
						myself.angry <- myself.angry+0.2;
						myself.generous <- myself.generous-0.1;
						myself.sleepy <- myself.sleepy+0.1;
						self.happy <- self.happy-0.2;
						self.angry <- self.angry+0.3;
						self.generous <- self.generous-0.1;
						self.sleepy <- self.sleepy+0.1;
					}
					else if(myself.generous > 0.5){
						write myself.gType + " is feeling generous and gives " + self.gType + " a hug";
						myself.happy <- myself.happy+0.2;
						myself.angry <- myself.angry-0.2;
						myself.generous <- myself.generous+0.3;
						myself.sleepy <- myself.sleepy-0.1;
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.2;
						self.generous <- self.generous+0.1;
						self.sleepy <- self.sleepy-0.1;
					}
					
				}else if(self.gType="tired"){
					if(myself.sleepy < 0.7 and myself.happy > 0.5){
						write myself.gType + " is chatting with another " + self.gType;
						myself.sleepy <- myself.sleepy+0.4;
						myself.happy <- myself.happy+0.2;
						myself.angry <- myself.angry-0.1;
						myself.generous <- myself.generous+0.1;
						self.sleepy <- self.sleepy+0.4;
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.1;
						self.generous <- self.generous+0.1;
					}
					else if(myself.angry > 0.4){
						write myself.gType + " is angry and unfriends " + self.gType;
						myself.sleepy <- myself.sleepy+0.5;
						myself.happy <- myself.happy-0.2;
						myself.angry <- myself.angry+0.4;
						myself.generous <- myself.generous-0.1;
						self.sleepy <- self.sleepy+0.5;
						self.happy <- self.happy-0.4;
						self.angry <- self.angry+0.4;
						self.generous <- self.generous-0.1;
						myself.friend <- nil;
					}
				}
			
		}else if(myself.gType="tired"){
			if(myself.dest.type="party"){
				if(self.gType="tired"){
					if(myself.sleepy < 0.5 and myself.happy > 0.15 and myself.angry < 0.2){
						write myself.gType + " is hanging out with another " + self.gType;
						myself.sleepy <- myself.sleepy+0.4;
						myself.happy <- myself.happy+0.1;
						myself.angry <- myself.angry-0.1;
						myself.generous <- myself.generous+0.1;
						self.sleepy <- self.sleepy+0.4;
						self.happy <- self.happy+0.1;
						self.angry <- self.angry-0.1;
						self.generous <- self.generous+0.1;
					}
					else if(myself.angry > 0.4){
						write myself.gType + " is angry and unfriends " + self.gType;
						myself.sleepy <- myself.sleepy+0.5;
						myself.happy <- myself.happy-0.4;
						myself.angry <- myself.angry+0.4;
						myself.generous <- myself.generous-0.1;
						self.sleepy <- self.sleepy+0.5;
						self.happy <- self.happy-0.4;
						self.angry <- self.angry+0.4;
						self.generous <- self.generous-0.1;
						myself.friend <- nil;
					}
				}
			}else{
				if(myself.sleepy<0.5 and self.sleepy<=1.0){
					write myself.gType + " is happy with " + self.gType;
					self.sleepy <- self.sleepy-0.5;
					self.happy <- self.happy+0.2;
					self.angry <- self.angry-0.4;
					myself.sleepy <- myself.sleepy-0.5;
					myself.happy <- myself.happy+0.2;
					myself.angry <- myself.angry-0.4;
				}else{
					write myself.gType + " is so tired with " + self.gType;
					self.sleepy <- self.sleepy+0.1;
					self.happy <- self.happy-0.3;
					self.angry <- self.angry+0.2;
					myself.sleepy <- myself.sleepy+0.1;
					myself.happy <- myself.happy-0.3;
					myself.angry <- myself.angry+0.2;
				}
			}
			
			
		}else if(myself.gType="journalist"){
			if(myself.dest.type!="party"){
				if(self.gType="tired"){
					if(myself.happy > 0.15 and myself.sleepy < 0.7){
						write myself.gType + " takes an interview with " + self.gType;
						myself.sleepy <- myself.sleepy+0.3;
						myself.happy <- myself.happy+0.2;
						myself.angry <- myself.angry-0.15;
						myself.generous <- myself.generous+0.1;
						self.sleepy <- self.sleepy+0.3;
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.15;
						self.generous <- self.generous+0.1;
					}
					else if(myself.angry > 0.2 or self.sleepy > 0.7){
						write myself.gType + " is too angry to interview such a sleepy person " + self.gType;
						myself.sleepy <- myself.sleepy+0.1;
						myself.happy <- myself.happy-0.2;
						myself.angry <- myself.angry+0.2;
						myself.generous <- myself.generous-0.1;
						self.sleepy <- self.sleepy+0.1;
						self.happy <- self.happy-0.2;
						self.angry <- self.angry+0.2;
						self.generous <- self.generous-0.1;
					}
				}
			}else{
				write myself.gType + " is at party, and not really happy with interview with " + self.gType;
				myself.sleepy <- myself.sleepy+0.1;
				myself.happy <- myself.happy-0.2;
				myself.angry <- myself.angry+0.2;
				myself.generous <- myself.generous-0.1;
				self.sleepy <- self.sleepy+0.1;
				self.happy <- self.happy-0.2;
				self.angry <- self.angry+0.2;
				self.generous <- self.generous-0.1;
			}
			
			
		}
		
//		self.interaction<-1;
//		myself.interaction<-1;
		
		
		}
		self.friend<-nil;
		
		
//		
		
	}

}

species Venue skills:[fipa]{
	int whenToStart<-1;
	int whenToEnd<-0;
	bool ongoing <- false;
	string type;
	
	rgb stage_color;
	
	aspect { 
		
		draw rectangle(4, 4) color:stage_color;
		
		
	}
	
	reflex venueHostingAnEvent when: (time = whenToStart and ongoing=false){//Send out a fipa inform message when an event is about to start

			write name + ": "+type+" is starting soon";
			if(type="concert"){
				string concert_type<- genre[rnd(length(genre)-1)];
				write "concert type:"+ concert_type;
				do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start',concert_type] ];
			}else{
				do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start'] ];
			}
			whenToEnd <-int(time+20*rnd(10,20));//calculate the time of duration for each event
			ongoing <- true;
//		}
		
	}
	
	reflex endConcert when: (time=whenToEnd) and ongoing = true{//send out a fipa inform message when an event is ending
		
		do start_conversation with: [to ::list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['end'] ];
		
		write name + 'end '+ type;
		whenToStart <- int(time+10*rnd(1,5));//calculate the time for when to start a new event
		ongoing <- false;
		
	}
	
	
}

experiment festival type:gui{
	output{
		display map type: opengl {
			species Guests;
			species Venue;

        
		}
		display chart_display refresh:every(10#cycles) {
             chart "Tired vs. Party" type: series size: {1, 0.5} position: {0, 0} {
                data "Happiness1" value: mean (tiredList collect each.happy) style: line color: #green;
             	data "Angry1" value: mean (tiredList collect each.angry) style: line color: #red;
             	data "Sleepy1" value: mean (tiredList collect each.sleepy) style: line color: #purple;
             	data "Generous1" value: mean (tiredList collect each.generous) style: line color: #orange;
             	data "Happiness2" value: mean (partyList collect each.happy) style: line color: #yellow;
             	data "Angry2" value: mean (partyList collect each.angry) style: line color: #gray;
             	data "Sleepy2" value: mean (partyList collect each.sleepy) style: line color: #black;
             	data "Generous2" value: mean (partyList collect each.generous) style: line color: #blue;
             	
        	}
             chart "Guests happiness" type: pie style: exploded size: {1, 0.5} position: {0, 0.5}{
           		data "Party guests happiness" value:mean ( partyList collect (each.happy)) color: #magenta ;
           		data "Tired guests happiness" value:mean ( tiredList collect (each.happy)) color: #blue ;
           		data "Chilled guests happiness" value:mean ( chillList collect (each.happy)) color: #green ;
           		data "Drunk guests happiness" value: mean (drunkList collect (each.happy) )color: #orange ;
           		data "Journalist guests happiness" value: mean (journalistList collect (each.happy)) color: #red ;	
         	 }
         
 	
     }
         
	}

	
}