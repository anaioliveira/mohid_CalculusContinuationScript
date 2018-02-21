
Installation
------------
To run this script (*.pl) you don't need any installation

Pre-requisites
------------
Perl 5 higher version (to run perl script)
(http://strawberryperl.com)

 "perl joinTimeSeries.pl -h"   give you more help about the options.

------------
to convert perl script to a executable file (*.exe), you have to install PAR::Packer from CPAN (it is free) and use pp utility:
 - install PAR::Packer
   > cpan PAR::Packer

 - run pp utility
   > pp -o joinTimeSeries.exe joinTimeSeries.pl
   (http://search.cpan.org/~autrijus/PAR-0.85_01/script/pp)

   
   
  