module Danger
  ASCII_ROBOT = <<-eorobot
  
  
         `.--::::::::::::--.`                     
      `::-...````````````...-:-                   
      //-.``             ```.:o.                  
      -s+:-..```````````..-:+so                   
       ./+ossoo++++++ooossoo/-                    
          ```.--odddm/-.```                       
                smddm:    ``                      
              ``hdhhds``  ``                      
        .so-::+:/:::::/+/::.                      
        `-/+++//:::-:://++s:`                     
       `.-:::---......--:::-..`                   
      `.....--:---.-------.....`   ..`            
      `:-.---::.:/://:::-::---:.-++/:.+.          
    ./oys++///////////////+-..:/sy+/+o+`          
 `-oysssoooo+++++++++//+oyo-`  `.:os/.            
 sysoo++++//////////////+dmy+-`  `./s`            
 syoo++///:::::::::::::odddhhhs+:-:+o             
 -hso++///:::::::::::+hmddhhhhddmyshs.`           
 `hyso++///::::::::ohmdddhhhddmmhyyyhdyo-`        
  yyso++so//ohhyyhdmmdddddddmmhyhhyyhddddy:`      
  oyso+o+/:dNNNNmmmdddddddmdsy+yh:sydddddddy-     
  /hso++/::NNmmmmmddddmmmds//o:oosshdmmdddddd/    
  :hsoo+/:-smNNmmmmmmmdyo+://oossysh`/dmdddddm-   
  /hyso+/////oydddhhso++/:///s+oo/sh  .mmdddddd`  
  `oyso+++oosyyyyysso+//:+s++sssysy.   :Nmddhdm/  
    +///+/////:::::::::://///+/:/+.    -s/:-:/o+  
     /+::/+///::::::::::///++/:/o/`   /+:-.....-. 
   -dyoo/:/oooooooooooooooo/-:+ssdd   +++oo+/:-:/ 
   .mmdsoo/:-.``````````.-:/+osydmo    +y+yy//+:. 
    smmmdysooo+/+//////++ossyddddm-    y.`s+      
    /mmmmmmmdddhyyyyyhdddmmdddddmm.    .-o/       
    `dmmmmmmmddddddddddmmmmdddddd+       `        
     `hmmmmmmmddddddddmmmmmddddmo                 
      :mmmmmmmdddddddddmmddddddm.                 
   .:+ommmmmmdddhhhhdddmmddddddm+:`               
   `-/oyddmmmmddddhddddmhhhhhhyo:.`               
      +yssyhdmddddddddmmooooosh/                  
   .+shdds+ssshhhhhhhhysooyhhddhs/.               
   `-oyhds+hhhsssssssshyhhhhhhhyss:               
   `.+oossohddddyssyhdmhyyyyso++ohh-              
  -oyhhysoosyhhdhhhhddhysso++////ody`             
 .ooosyhhhysoosyhhhhysooooys/////+hd/             
 +oo++oosyhhhysooso+++/ohs+hs/////odh.            
:oooo++++oosyhhhy+//////odosd+/////ydo            
/ooooo+++oooooohdy+/////+hy+hy/////ohd-           
`:+oooooooooo+:+hdy//////odsodo/////sh:           
   ./+oo+++ooo//hddo//////yhoyh+//-.-`            
     `-++o++ooo:oddh//////+hy+h/`                 
        .:++++o+/odds//////oh::                   
           -/++o/+hdd+///-.-`                     
             `:++:+hdy-`                          
                .:+ss-                            


      DANGER, WILL ROBINSON! DANGER!
      
  eorobot
  
  class WillRobinson < Danger::Runner
    self.description = 'Super-secret easter egg that prints out The Robot'
    self.command = 'willrobinson'
    
    def validate!
    end

    def run
      puts ASCII_ROBOT
    end
  end
end
