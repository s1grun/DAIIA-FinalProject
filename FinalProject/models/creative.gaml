/***
* Name: Festival
* Author: sigrunarnasigurdardottir
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model creative

/* Insert your model definition here */
global {
	point centerLocation <- {50, 50};
    list<string> genre <- ["rock", "pop", "folks", "jazz"];
    list<string> guestTypes <- ["chill", "party", "tired", "drunk", "journalist"];
    list<Guests> tiredList <-[];
    list<Guests> partyList <-[];
    list<Guests> chillList <-[];
    list<Guests> drunkList <-[];
    list<Guests> journalistList <-[];
    
    
	init {
		//We have a health center for guests that become too angry
		create Health_center with:(location:centerLocation);
		
		point storeLocation1 <- {25, 25};
		create Guests number: 50;

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
		

		create Stage number: 2 with:(stage_color:#blue,type:"bar");
		
		create Stage number: 1 with:(stage_color:#yellow,type:"party");
		
		create Stage number: 1 with:(stage_color:#green,type:"concert");
	
	}
	
	
}










species Guests skills:[moving, fipa]{

	int statusFeeling <- 0;    // var0 equals 0, 1 or 2; 0->nothing,1->thirsty,2->hungry
	point storeDestination <- nil; // To store the location of a store
	point returnBack <- rnd({0.0, 0.0, 0.0},{100.0,100.0,0.0});
	point guestLocation <- nil;
	int status <- 0;
	rgb my_color <- #blue;
	string gType <- guestTypes[rnd(length(guestTypes) - 1)];
	Stage dest <-nil;
	list stage_list<-[];
	int movingStatus <- 0; // 0-> do wander,1-> go to stage,2-> at stage;
	int interaction <-0; //0->no interaction, 1->interact with someone.
	float generous <- rnd(0.0,1.0);
	Guests friend <- nil;
	float happy <- rnd(0.0,0.5);
	float sleepy <- rnd(0.0,0.5);
	float angry <- rnd(0.0,0.5);
	float partyMood <- rnd(0.0,0.5);
	string count;
	bool friend_frozen <-false;
	
	
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
		}else if(happy < -1){
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


	reflex getInfo when:!(empty(informs)){
		
		loop msg over: informs{
			Stage spot<- Stage(agent(msg.sender));
			if(msg.contents[0]="start"){
				add spot to:stage_list;
				if(flip(0.5) and movingStatus!=3 and  movingStatus!=4){
					if(friend != nil and spot.type="concert"){
						write name + " sending invite to friend " + friend;
						do start_conversation with: [to :: list(friend), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['invitation',spot] ];
						dest<- spot;
						movingStatus <-1;	
					}else{
						dest<- spot;
						movingStatus <-1;
					}
				}

			}else if(msg.contents[0]="end"){
				remove spot from:stage_list;
				if(dest!=nil){
					if(dest=spot){
						if(length(stage_list) = 0){
							do wander;
						}else{
							
							remove self from: dest.guestsList;
							
							dest<- stage_list[rnd(length(stage_list) - 1)];
						}
						
						if( movingStatus!=3 and  movingStatus!=4){
							movingStatus <-1;
						}
						
						
					}
				}
			}else if (msg.contents[0]="invitation"){
				spot<-msg.contents[1];
				add spot to:stage_list;	
				remove self from: dest.guestsList;						
				dest<- spot;
				movingStatus <-1;
				write name +" going to concert with friend " + msg.sender;
			}
		}
			
	}
	
	reflex goToStage when:movingStatus=1{
		do goto target:dest;
		
	}
	
	reflex nearStage when: dest!=nil and distance_to(self,dest)<=7 and movingStatus=1{
		movingStatus <- 2;
		dest.guestsList <+ self;	
		if(friend != nil){
			ask friend {
//				write name + "is no longer friend with " + friend;
				myself.friend <- nil;
				self.friend <- nil;
			}
		}	
	}
	
	
	reflex atStage when: movingStatus=2 and friend=nil{
		do wander;
		
		
		if(gType="drunk"){
			ask Guests at_distance 3{
					if(self.gType="drunk"){
						if(flip(0.9)){
//							write myself.name +":drunk guy make friends with "+self.name+":drunk guy";
							myself.friend<- self;
							self.friend<- myself;
//							myself.happy<-myself.happy+0.1;
//							self.happy<-self.happy+0.1;
						}
					}else if(self.gType="journalist"){
						if(flip(0.3)){
							myself.friend<- self;
							self.friend<- myself;
//							write myself.name +":drunk guy interview with "+self.name+":journalist, jouranlist get angry and drunk guy get happy";
//							self.angry <- self.angry+0.1;
//							myself.happy<-myself.happy+0.1;
						}
					}else{
						if(self.happy>=0.5){
							myself.friend<- self;
							self.friend<- myself;
//							write myself.name + ":drunk guy meet "+ self.gType+" ";
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
		
			if(length(Guests at_distance 3)>5 or sleepy>0.7){
				write "tired guy leave the "+dest.type;
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
	
	//If a guest is angry and his friend is generous and not a journalist,
	//then his friend will take him to the health center
	reflex outRage when: angry>1.5 and movingStatus=2{
		if friend != nil{
			if(friend.generous>0.5 and friend.gType!="journalist"){
				ask friend{
//					self.friend_frozen<- true;
//					myself.friend_frozen <- true;
					movingStatus<-3;
					myself.movingStatus<-3;
					color <- #red;
					write name + " go to Health_center with grumpy guy:"+ myself.name;
					color <- #blue;
					remove self from: dest.guestsList;
				}
				remove self from: dest.guestsList;
				
			}
		}
	}
	
	//To go to the health center
	reflex gotoHealthCenter when: movingStatus=3{
		Health_center hc<-one_of(Health_center);
		do goto target:hc;
		
		if( distance_to(location, hc.location) <5){
			movingStatus<-4;
		}
	}
	
	//When they are at the health center both of their angry level will decrese and they will come a bit sleepy
	reflex atHealthCenter when: movingStatus=4{
		if(friend!=nil){
			ask friend{
				self.angry <-self.angry-0.1;
				self.sleepy <- self.sleepy+0.2;
				myself.angry <-0.0;
				myself.sleepy <-myself.sleepy+0.2;
				movingStatus<-1;
			}
		}
		movingStatus<-1;
	}
	
	reflex withFriend when: movingStatus=2 and friend!=nil {
		ask friend {
			
		
		if(myself.gType="drunk"){//When a drunk guest meets a friend and depending how he's feeling and on the type of guest his friend is. 
			if(self.gType="party" or self.gType="chill"){
					if(myself.generous > 0.25 and myself.angry < 0.5){
						write myself.gType + " is feeling generous and buys " + self.gType + " a drink";
						if(self.happy >= 0.5 and self.angry < 0.2){
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
					else if(myself.angry > 0.3 and myself.generous < 0.2){
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
					else if(myself.happy > 0.5){
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
						myself.angry <- myself.angry+0.2;
						myself.generous <- myself.generous+0.1;
						self.sleepy <- self.sleepy+0.4;
						self.happy <- self.happy+0.3;
						self.angry <- self.angry-0.1;
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
		}else if(myself.gType="party"){
//			if(friend.gType){
					if(myself.angry > 0.5 and myself.sleepy < 0.5){
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
					else if(myself.happy > 0.3 and myself.sleepy < 0.5) {
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
		}else if(myself.gType="chill"){
			if(self.gType="journalist"){
					if(myself.sleepy > 0.3){
						write myself.gType + " is feeling too tired to be interviewd by " + self.gType;
						myself.happy <- myself.happy-0.2;
						myself.angry <- myself.angry+0.1;
						myself.generous <- myself.generous-0.1;
						myself.sleepy <- myself.sleepy+0.3;
						self.happy <- self.happy-0.2;
						self.angry <- self.angry+0.3;
						self.generous <- self.generous-0.1;
						self.sleepy <- self.sleepy-0.1;
					}
					if(myself.happy > 0.5 and myself.angry < 0.5 and myself.generous < 0.2){
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
					else if(myself.angry > 0.5){
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
					else if(myself.generous > 0.2){
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
					if(myself.happy > 0.5 and myself.angry < 0.2 and myself.generous < 0.2){
						write myself.gType + " is feeling happy and chills with " + self.gType;
						myself.happy <- myself.happy+0.2;
						myself.angry <- myself.angry-0.2;
						myself.generous <- myself.generous+0.1;
						myself.sleepy <- myself.sleepy-0.1;
						self.happy <- self.happy+0.1;
						self.angry <- self.angry-0.2;
						self.generous <- self.generous+0.1;
						self.sleepy <- self.sleepy-0.1;
					}
					else if(myself.angry > 0.3){
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
					else if(myself.generous > 0.2){
						write myself.gType + " is feeling generous and gives " + self.gType + " a hug";
						myself.happy <- myself.happy+0.2;
						myself.angry <- myself.angry-0.1;
						myself.generous <- myself.generous+0.3;
						myself.sleepy <- myself.sleepy-0.1;
						self.happy <- self.happy+0.2;
						self.angry <- self.angry-0.1;
						self.generous <- self.generous+0.1;
						self.sleepy <- self.sleepy-0.1;
					}
					
				}else if(self.gType="tired"){
					if(myself.sleepy < 0.7 and myself.happy > 0.7){
						write myself.gType + " is chatting with another " + self.gType;
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
			
		}else if(myself.gType="tired"){
			if(self.gType="tired"){
					if(myself.sleepy < 0.7 and myself.happy > 0.15 and myself.angry < 0.2){
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
			}else{
				write myself.gType + " is getting annoying with " + self.gType;
				myself.sleepy <- myself.sleepy+0.1;
				myself.happy <- myself.happy-0.4;
				myself.angry <- myself.angry+0.4;
				myself.generous <- myself.generous-0.1;
				self.sleepy <- self.sleepy+0.5;
				self.happy <- self.happy-0.4;
				self.angry <- self.angry+0.4;
				self.generous <- self.generous-0.1;
			}
			
		}else if(myself.gType="journalist"){
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
			
		}
		
//		self.interaction<-1;
//		myself.interaction<-1;
		
		
		}
		self.friend<-nil;
		
		
//		
		
	}
		
	
	
	
	
	



}

species Health_center{
	aspect default{
		draw rectangle(4, 4) color:#red;
	}
	
}


species Stage skills:[fipa]{
	int whenToStart<-1;
	int whenToEnd<-0;
	list<Guests> guestsList;
	bool ongoing <- false;
	string type;
	Guests guest;
	rgb stage_color;
	float globalAngry <- 0.0;
	
	aspect { 
		
		draw rectangle(4, 4) color:stage_color;
		
		
	}
	
	
	reflex stageHostingConcert when: (time = whenToStart and ongoing=false)  {
		
			write name + ": "+type+" is starting soon";
			if(type="concert"){
				string concert_type<- genre[rnd(length(genre)-1)];
				write "concert type:"+ concert_type;
				do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start',concert_type] ];
			}else{
				do start_conversation with: [to :: list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['start'] ];
			}
			whenToEnd <-int(time+20*rnd(10,20));
			ongoing <- true;
		
	}
	
	//Here we calculate the global angry level for each stage, and if
	//it goes over 10 then the stage  will end an event.
	reflex calculateGlobalAngryLevel {
		globalAngry<-0.0;
		if(type="concert" or type="party" or type="bar"){
			loop g over: guestsList {
				globalAngry <- globalAngry + g.angry;
//				write "Guest angry value at concert" +g.angry;
				
			}
			if(globalAngry >= 10.0){
					color<-#black;
					write "The angry level is too high, concert ends now" + globalAngry;
					do start_conversation with: [to ::list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['end'] ];
					write name + ' end '+ type;
					whenToStart <- int(time+20*rnd(1,5));
					ongoing <- false; 
					color<-#blue;
					guestsList<-[];
				}
		}
	}
	
	reflex endConcert when: (time=whenToEnd) and ongoing = true{
		
		do start_conversation with: [to ::list(Guests), protocol :: 'fipa-contract-net', performative :: 'inform', contents :: ['end'] ];
		
		write name + 'end '+ type;
		whenToStart <- int(time+10*rnd(1,5));
		ongoing <- false;
		guestsList<-[];
		
	}
	
	
}

experiment creative type:gui{
	output{
		display map type: opengl {
			species Guests;
			species Stage;
			species Health_center;
			
        
		}
		display chart_display refresh:every(10#cycles) {
             chart "globalAngry of Stages" type: series size: {1, 0.5} position: {0, 0} {
                data "bar1" value: Stage[0].globalAngry style: line color: #green;
             	data "bar2" value: Stage[1].globalAngry style: line color: #red;
             	data "party" value: Stage[2].globalAngry style: line color: #purple;
             	data "concert" value: Stage[3].globalAngry style: line color: #orange;
             	
        	}
         
 	
     }
         
	}

	
}