#!/usr/bin/perl -w

################################################################
################################################################
## created by: Jorge Palma, IST                               ##
## date:       2014-06-04                                     ##
## version:    v1.0                                           ##
## This script join time series from MARETEC data time series ##
################################################################
################################################################

use strict;
use Encode qw(encode_utf8);
use utf8;
use Getopt::Long;
use File::Path;
use File::Copy;

$| = 1; ## Turn on "autoflush"

my $startTime = time;

#####################################################
##### setup my defaults arguments
my $thisfilename = $0; $thisfilename =~ s/\.pl|\.exe//;
my $configFile   = $thisfilename.'.dat';
my $verbose	     = "";
my $testConfig   = "";
my $help         = "";

#####################################################
#### USAGE
my $USAGE =<<USAGE;

     Usage:
         perl $0 [OPTION1 OPTION2 ...]
         This tools join time series...
         See configuration file.

         OPTIONS:
             -c, --config=CONFIG_FILE    path for configuration file. Default is "$configFile"
             -v, --verbose               Increase verbosity of output
             -tcf                        test only config file format
             -h, --help                  show this help

USAGE
#
#####################################################
#### OPTIONS
GetOptions(
    'config=s'	=> \$configFile,
	'verbose' 	=> \$verbose,
	'tcf'		=> \$testConfig,
    'help!'		=> \$help,
) or die "Incorrect usage!\n";


if($help) {
    print "$USAGE\n";
    exit 0;
}

## verify if config file exist
if(!-e $configFile){
	print "\n\n*****ERROR*****\n";
	print "perl can't find config file $configFile\n";
	print "Make sure that the file exist!\n\n";
	print "The program will abort.\n";
	exit 0;
}

#####################################################
##### read config file
my $timeseriesDir;
my $runType;
my $strDate=0; my $strSecEpoch=4102444799000; ## 31 Dec 2099 23:59:59 GMT
my ($endDate,$endSecEpoch);
my $backupDir='BACKUP'; my $storageDir='STORAGE'; my $publishDir='PUBLISH';
my (@staList,@extList);

&readConfigFile();
if($verbose or $testConfig){
	print "\n\n======== Configuration arguments: ========\n\n";
	print " Timeseries dir: $timeseriesDir\n";
	print " Run type: $runType\n";
	print " Start date: $strDate, $strSecEpoch\n";
	print " End date:   $endDate, $endSecEpoch\n";	
	print " Other dirs: $publishDir, $storageDir, $backupDir \n";
	print " Stations:\n"; print "  $_\n" foreach(@staList); print"\n";
	print " Properties:\n"; print "  $_\n" foreach(@extList);print"\n";
	print "=============================================\n\n";
}
exit if($testConfig);

#####################################################
##### create directories
if($runType eq 'NOPE'){
	if(-e $backupDir)  {rmtree $backupDir;}
	if(-e $storageDir) {rmtree $storageDir;}
	if(-e $publishDir) {rmtree $publishDir;}
}

unless(-e $backupDir  or mkdir ($backupDir, 0755)) {die "Unable to create $backupDir";}
unless(-e $storageDir or mkdir ($storageDir,0755)) {die "Unable to create $storageDir";}
unless(-e $publishDir or mkdir ($publishDir,0755)) {die "Unable to create $publishDir";}

#####################################################
#### Process Time Series ####

##### get Time Series dirs
opendir( DIR, $timeseriesDir ) or die "Couldn't open dir '$timeseriesDir': $!";
 #my @dirs = grep( /^\w*$/, readdir(DIR) );
 my @dirs = readdir(DIR);
 @dirs = sort(@dirs);
closedir DIR;

#### Process each time series
my @childs = ();
foreach(@extList){
	my $pid = fork();	
	if ($pid) {
		# parent Process... ($pid = PID)
		#print "pid is $pid, new child...\n";
		push(@childs, $pid);
	} elsif ($pid == 0) {
		# child Process... ($pid = 0)			
		process($_);
		exit 0;
	} else {
		die "couldnt fork: $!\n";
	}
}

foreach (@childs) {
	my $tmp = waitpid($_, 0);
	print "done with pid $tmp\n";
}

#####################################################
#### copy output files to storageDir and backupDir
#&copyOutputFiles();


#####################################################
my $duration = time - $startTime;
print "\n\nExecution time: $duration s\n" if($verbose);

#### END PROGRAM ####


#####################################################
######## SUBROUTINES ################################
#####################################################

#####################################################
sub readConfigFile{
	my ($str_y,$str_m,$str_d,$str_H,$str_M,$str_S);
	my ($end_y,$end_m,$end_d,$end_H,$end_M,$end_S);
	my $tmp;
	
	open FILE, "<", "$configFile" or die $!;
	my @lines = <FILE>;
	for(my $i = 0; $i <= $#lines; $i++) {
		my $line = $lines[$i];
		next if($line =~ /^\s*$/);
		next if($line =~ /^\s*#.*$/);
		$line =~ s/\s*#.+$//g;
		
		if($line =~ /^\s*TIMESERIES_PATH\s*:/){
			if($line =~ /^\s*TIMESERIES_PATH\s*:\s*(.+)$/){
				$timeseriesDir = $1;
			}else{
				print "TIMESERIES_PATH -> error format.\n";
				print "must be: TIMESERIES_PATH : path_to_times_series \n";
				print "The program will abort.\n";
				exit 0;
			}
		}
		elsif($line =~ /^\s*RUN_TYPE\s*:/){
			if($line =~ /^\s*RUN_TYPE\s*:\s*(NOPE|OPE)$/){
				$runType = $1;
			}else{
				print "RUN_TYPE -> error format.\n";
				print "must be: RUN_TYPE : NOPE or OPE \n";
				print "The program will abort.\n";
				exit 0;
			}
		}
		elsif($line =~ /^\s*START\s*:/){
			if($line =~ /^\s*START\s*:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/){
				$str_y = sprintf '%04d',$1;
				$str_m = sprintf '%02d',$2;
				$str_d = sprintf '%02d',$3;
				$str_H = sprintf '%02d',$4;
				$str_M = sprintf '%02d',$5;
				$str_S = sprintf '%02d',$6;
				$strDate = $str_y.'-'. $str_m.'-'.$str_d;
				$strSecEpoch =  gmDateTime2SecEpoch($str_S, $str_M, $str_H, $str_d, $str_m, $str_y);
			}else{
				print "START -> error format.\n";
				print "must be: START : yyyy mm dd HH MM SS \n";
				print "The program will abort.\n";
				exit 0;
			}
		}
		elsif($line =~ /^\s*END\s*:/){
			if($line =~ /^\s*END\s*:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/){
				$end_y = sprintf '%04d',$1;
				$end_m = sprintf '%02d',$2;
				$end_d = sprintf '%02d',$3;
				$end_H = sprintf '%02d',$4;
				$end_M = sprintf '%02d',$5;
				$end_S = sprintf '%02d',$6;
				$endDate = $end_y.'-'. $end_m.'-'.$end_d;
				$endSecEpoch =  gmDateTime2SecEpoch($end_S, $end_M, $end_H, $end_d, $end_m, $end_y);
			}else{
				print "END -> error format.\n";
				print "must be: END : yyyy mm dd HH MM SS \n";
				print "The program will abort.\n";
				exit 0;
			}
		}
		elsif($line =~ /^\s*PUBLISH_PATH\s*:/){
			if($line =~ /^\s*PUBLISH_PATH\s*:\s*(.+)/){
				$tmp = $1;
				$publishDir = $tmp if($tmp =~ /\w+/); ## new publishDir if $1 is not empty
			}else{
				print "PUBLISH_PATH -> error format.\n";
				print "must be: PUBLISH_PATH : path_to_publish \n";
				print "The program will abort.\n";
				exit 0;
			}
		}
		elsif($line =~ /^\s*STORAGE_PATH\s*:/){
			if($line =~ /^\s*STORAGE_PATH\s*:\s*(.+)/){
				$tmp = $1;
				$storageDir = $tmp if($tmp =~ /\w+/); ## new storageDir if $1 is not empty
			}else{
				print "STORAGE_PATH -> error format.\n";
				print "must be: STORAGE_PATH : path_to_storage \n";
				print "The program will abort.\n";
				exit 0;
			}
		}
		elsif($line =~ /^\s*BACKUP_PATH\s*:/){
			if($line =~ /^\s*BACKUP_PATH\s*:\s*(.+)/){
				$tmp = $1;
				$backupDir = $tmp if($tmp =~ /\w+/); ## new backupDir if $1 is not empty
			}else{
				print "BACKUP_PATH -> error format.\n";
				print "must be: BACKUP_PATH : path_to_backup \n";
				print "The program will abort.\n";
				exit 0;
			}
		}
		elsif($line =~ /^\s*<begin_station_list>/){
			while($lines[++$i] !~ /^\s*<end_station_list>/ ){
				if($lines[$i] =~ /^\s*(.+)/){
					my $sta = $1; $sta =~ s/^\s+|\s+$//g; ## trim both ends 
					push(@staList,$sta);
				}
			}
			@staList = sort(@staList);
		}
		elsif($line =~ /^\s*<begin_extension_list>/){
			while($lines[++$i] !~ /^\s*<end_extension_list>/ ){
				if($lines[$i] =~ /^\s*(.+)/){
					my $ext = $1; $ext =~ s/^\s+|\s+$//g; ## trim both ends 
					push(@extList,$ext);
				}
			}
			@extList = sort(@extList);
		}
	}
}

#####################################################
sub process {
	my $extFile = shift @_;
	
	my %fh;
	
	#####################################################
	##### process each Time Series dir
	my $isFirstTimeSeriesFile = 1;
	foreach my $dir (@dirs) {
		next if ( $dir =~ m/^\./ );
		my $readTimeStr = time;
		
		if($dir =~ /^(\d\d\d\d)-(\d\d)-(\d\d)_(\d\d\d\d)-(\d\d)-(\d\d)/){
			my $curStr_secEpoch =  gmDateTime2SecEpoch(0, 0, 0, $3, $2, $1);
			my $curEnd_secEpoch =  gmDateTime2SecEpoch(0, 0, 0, $6, $5, $4);
			
			if($curStr_secEpoch < $strSecEpoch ){
				next;
			}elsif($curStr_secEpoch >= $endSecEpoch){
				last;
			}
		}else{
			next;
		}
		
		my $path = "$timeseriesDir/$dir";
		print "process $extFile $dir\n";

		#####################################################
		##### process each station file
		foreach my $staFile (@staList){
			my $filename = "$staFile.$extFile";
			my $pathFile = "$timeseriesDir/$dir/$filename";
			#print "   Process file: $pathFile\n" if($verbose);
			
			my @lines = ();
			
			if(-e $pathFile ){			
				##### read data file from file
				open FileIn,  "<$pathFile"   or die $!;
					@lines = <FileIn>;		
				close FileIn;
			}else{
				print "filename $filename doesn't exist.\n" if($verbose);
				next;
			}
			
			#####################################################
			##### get data from file
			my ($station,$loc_i,$loc_j,$loc_k,$iniDateTime,$iniSecEpoch,$timeUnits,$modelDomain);
			my ($headerTimeSerie,@timeSerie,@residual);
			my ($lastSecEpochFileBefore,$firstSecEpoch,$lastSecEpoch);		
			my @header = ();
			for(my $i = 0; $i <= $#lines; $i++) {
				my $line = $lines[$i];
				next if($line =~ /^\s*$/);
				next if($line =~ /^\s*#.*$/);
				$line =~ s/\s*#.+$//g;
				$line =~ s/^\s+//g;
				
				if($line =~ /^\s*NAME\s*:/){
					if($line =~ /^\s*NAME\s*:\s*(.+)$/){
						$station = $1;
						push(@header,$line) if($isFirstTimeSeriesFile);
						if($station ne $staFile){
							print "WARNING. File name: $staFile does't match NAME: $station\n";
							## print "The program will abort.\n";
							## exit 0;
						}
					}else{
						print "FATAL ERROR. Bad format in NAME\n";
						print "The program will abort.\n";
						exit 0;
					}
				}
				elsif($line =~ /^\s*LOCALIZATION_I\s*:/){
					if($line =~ /^\s*LOCALIZATION_I\s*:\s*(\d+)/){
						$loc_i = $1;
						push(@header,$line) if($isFirstTimeSeriesFile);
					}
				}
				elsif($line =~ /^\s*LOCALIZATION_J\s*:/){
					if($line =~ /^\s*LOCALIZATION_J\s*:\s*(\d+)/){
						$loc_j = $1;
						push(@header,$line) if($isFirstTimeSeriesFile);
					}
				}
				elsif($line =~ /^\s*LOCALIZATION_K\s*:/){
					if($line =~ /^\s*LOCALIZATION_K\s*:\s*(\d+)/){
						$loc_k = $1;
						push(@header,$line) if($isFirstTimeSeriesFile);
					}
				}
				elsif($line =~ /^\s*SERIE_INITIAL_DATA\s*:/){
					if($line =~ /^\s*SERIE_INITIAL_DATA\s*:\s*(\d+\.*\d*)\s+(\d+\.*\d*)\s+(\d+\.*\d*)\s+(\d+\.*\d*)\s+(\d+\.*\d*)\s+(\d+\.*\d*)/){
						$iniDateTime = sprintf('%04d-%02d-%02d %02d:%02d:%02d', $1,$2,$3,$4,$5,$6);
						$iniSecEpoch = gmDateTime2SecEpoch($6,$5,$4,$3,$2,$1);
						push(@header,$line) if($isFirstTimeSeriesFile);
					}
				}
				elsif($line =~ /^\s*TIME_UNITS\s*:/){
					if($line =~ /^\s*TIME_UNITS\s*:\s*(.+)/){
						$timeUnits = $1;
						push(@header,$line) if($isFirstTimeSeriesFile);
					}
				}
				elsif($line =~ /^\s*MODEL_DOMAIN\s*:/){
					if($line =~ /^\s*MODEL_DOMAIN\s*:\s*(.+)/){
						$modelDomain = $1;
						push(@header,$line) if($isFirstTimeSeriesFile);
					}
				}
				elsif($line =~ /^\s*<BeginTimeSerie>/){
					$headerTimeSerie = $lines[$i-1];
					$headerTimeSerie =~ s/(^\s*Seconds\s*)//;
					push(@header,$headerTimeSerie);
					push(@header,$line);
					
					while($lines[++$i] !~ /^\s*<EndTimeSerie>/ ){
						if($lines[$i] =~ /^\s*(.+)/){
							push(@timeSerie,$1);
						}
					}
				}
				# elsif($line =~ /^\s*<BeginResidual>/){
					# while($lines[++$i] !~ /^\s*<EndResidual>/ ){
						# if($lines[$i] =~ /^\s*(.+)/){
							# push(@residual,$1);
						# }
					# }
				# }				
			}
			
			#print "\n\n $station, $loc_i, $loc_j, $loc_k\n";
			#print "$iniDateTime,$iniSecEpoch,$timeUnits,$modelDomain\n";
			#print "$headerTimeSerie\n";
			#print "@timeSerie\n";
			#print "@residual\n";
			
			#####################################################
			##### write header, only if is first time series file
			#if($isFirstTimeSeriesFile and (!-e "$publishDir/$filename" or $runType eq 'NOPE') ){
			if($isFirstTimeSeriesFile and !-e "$publishDir/$filename"){
				open FileOut,  ">$publishDir/$filename"   or die $!;				
				print FileOut $_ foreach(@header);					
				close FileOut;
			}
		
			#####################################################
			##### append new data in file history			
			my @newData = ();
			for(my $i = 0; $i <= $#timeSerie-1; $i++) {
				if($timeSerie[$i] =~ /(^\s*\d+.\d*\s*)/){
					push(@newData,$');
				}			
			}
						
			if($runType eq 'NOPE'){
				if( ! $fh{$filename}){
					## only close file in the end
					open my $FILEIN,  ">>", "$publishDir/$filename"   or die $!;				
					$fh{$filename} = $FILEIN;
				}

				foreach (@newData){
					chomp($_);
					print {$fh{$filename}} "$_\n";
				}				
			}
			elsif($runType eq 'OPE'){
				if( ! $fh{$filename}){
					## only close file in the end
					open my $FILEIN,  "+<", "$publishDir/$filename"   or die $!;			
					$fh{$filename} = $FILEIN;
				}

				my @oldData = ();
				my $fh = $fh{$filename};
				seek($fh,0,0);
				@oldData = <$fh>;

				#my $iniIndex = $#oldData - $daysToMatch*24*(3600/$timeStep);
				
				foreach my $new (@newData){
					if($new =~ /\s*(\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+.\d+)\s+/){  ## 2014   4   1  23  50   0.0000
						my $curNewData = $1;
						my $secEpoch_new;
						if($new =~ /\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+.\d+)\s+/ ){   #2014   6   2  23  50   0.0000
							$secEpoch_new = gmDateTime2SecEpoch($6,$5,$4,$3,$2,$1);
						}
						
						# my @index = grep { $oldData[$_] =~ /$1/ } $iniIndex..$#oldData;		## give array index where match $1

						# ## new data
						# if($#index == -1){  
							# push(@oldData, $new);
							# #print "index = -1\n";
						# ## update data
						# }elsif( $#index == 0){
							# $oldData[$index[0]] = $new;
							# #print "index = 0\n";
						# ## duplicate data
						# }elsif($#index > 0){
							# print "\nDuplicate data in $filename!!\n";
							# print "Run All with RunType: NOPE.\n";
							# print "The program will abort.\n";
							# exit 0;
						# }
						
						
						my $indexMatch = -1;
						my $isMiddle = 0;
						for(my $i = $#oldData; $i >= 0 ; $i--) {
							if($oldData[$i] =~ /$curNewData/ ){
								$indexMatch = $i;
								$isMiddle = 0;
								last;
							}
							
							if($oldData[$i] =~ /\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+.\d+)\s+/ ){   #2014   6   2  23  50   0.0000
								my $secEpoch_old = gmDateTime2SecEpoch($6,$5,$4,$3,$2,$1);
								if($secEpoch_old < $secEpoch_new){
									$indexMatch = $i;
									$isMiddle = 1;
									last;
								}
							}
						}

						## new data
						if($indexMatch == -1){  
							push(@oldData, $new);
							#print "indexMatch = -1\n";
						## update data
						}elsif($indexMatch != -1 && !$isMiddle){
							$oldData[$indexMatch] = $new;
							#print "indexMatch = $indexMatch\n";
						}elsif($indexMatch != -1 && $isMiddle){
							splice (@oldData, $indexMatch+1, 0, $new);
						}
					}			
				}			
				
				seek($fh,0,0);
				foreach (@oldData){
					chomp($_);
					#print "$_\n";
					print $fh "$_\n";
				}		
			}
		}
		$isFirstTimeSeriesFile = 0;
		
		my $durReadTimeStr = time - $readTimeStr;
		#print "time: $durReadTimeStr\n";
	}

	#####################################################
	##### close all open output files --> NOPE RunType mode
	foreach my $key ( keys %fh ){
		close $fh{$key};
	}
	
}

sub copyOutputFiles{
	
	print "\nCopying files to BACKUP_DIR and STORAGE_DIR...\n";
	## create date dir in storageDir and backupDir
	my $date_dir;
	$date_dir = $strDate.'_'.$endDate;
	unless(-e "$backupDir/$date_dir"   or mkdir ("$backupDir/$date_dir", 755)) {die "Unable to create $backupDir/$date_dir";}
	unless(-e "$storageDir/$date_dir"  or mkdir ("$storageDir/$date_dir", 755)) {die "Unable to create $storageDir/$date_dir";}


	## copy files to storageDir and backupDir
	opendir OUTPUTDIR, $publishDir or die "Could not opendir $publishDir: $!\n";
	 my @allfiles = grep { $_ ne '.' and $_ ne '..' } readdir OUTPUTDIR ;
	closedir(OUTPUTDIR);

	my @files    = grep { !-d } @allfiles ;
	my @select_files = grep /\.\w+/, @files;
	for my $file (@select_files) {
		copy ("$publishDir/$file", "$backupDir/$date_dir")  or die "Failed to copy $file to $backupDir: $!\n";
		copy ("$publishDir/$file", "$storageDir/$date_dir") or die "Failed to copy $file to $storageDir: $!\n";
	}

	print "\nCreated ".@files." new files\n" if($verbose);
	# print map "$_\n", @allfiles;
}

#####################################################
#####################################################
#####################################################
#----------------------------------------------------
sub gmDateTime2SecEpoch {
    use Time::Local;
    my ($sec, $min, $hour, $day, $month, $year) = @_;
	
    my $month2 = $month - 1;
    my $year2  = $year - 1900;
    my $SecEpoch = timegm ($sec, $min, $hour, $day, $month2, $year2);

    return ($SecEpoch);

}
#----------------------------------------------------

