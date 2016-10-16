if {$argc == 5} {
    set cenario [lindex $argv 0]
    set fonte [lindex $argv 1]
    set janela [lindex $argv 2]
    set quebra [lindex $argv 3]
    set 4_2 [lindex $argv 4]
} else {
    puts "Format: ns exUDPeTCP.tcl <cenario> <fonte> (TCP ou UDP) <janela> <quebra> (0 ou 1) <ex 4.2> (0 ou 1) (Para utilizar valores por omissão, escreva 0)"
    exit 1
}

set ns [new Simulator]

#------------Set Dynamic Routing Protocol---------------#
$ns rtproto DV

#-----------Create nam objects-------------------------#
set tf [open out.tr w]
set nf [open out.nam w]

$ns trace-all $tf
$ns namtrace-all $nf

#---------finish procedure---------#
proc fim {} {
    global ns tf
    global ns nf
    $ns flush-trace
    close $tf
    close $nf
    exec nam out.nam
    exit 0
}

#----------Create Servers-Routers-Client-------------#
set ServerA [$ns node]
set R1 [$ns node]
set R2 [$ns node]
set Receiver [$ns node]
set ServerB [$ns node]
set R5 [$ns node]
set R6 [$ns node]

#---creating duplex link---------#
$ns duplex-link $ServerA $R1 100Mb 10ms DropTail
$ns duplex-link $R1 $R2 1Gb 10ms DropTail
$ns duplex-link $R2 $Receiver 10Mb 3ms DropTail
$ns duplex-link $ServerB $R5 10Mb 10ms DropTail
$ns duplex-link $R5 $R6 1Gb 10ms DropTail
$ns duplex-link $R1 $R5 5Mb 10ms DropTail
$ns duplex-link $R2 $R6 10Mb 10ms DropTail

#----------------creating orientation------------------#
$ns duplex-link-op $ServerA $R1 orient right
$ns duplex-link-op $R1 $R2 orient right
$ns duplex-link-op $R2 $Receiver orient right
$ns duplex-link-op $R1 $R5 orient down
$ns duplex-link-op $R2 $R6 orient down
$ns duplex-link-op $R5 $R6 orient right
$ns duplex-link-op $R5 $ServerB orient left

#------------Labelling----------------#
$ns at 0.0 "$ServerA label ServerA"
$ns at 0.0 "$ServerB label ServerB"
$ns at 0.0 "$Receiver label Receiver"
$ns at 0.0 "$R1 label R1"
$ns at 0.0 "$R2 label R2"
$ns at 0.0 "$R5 label R5"
$ns at 0.0 "$R6 label R6"

#------------Colours----------------#
$ServerA color red
$ServerB color red
$Receiver color blue

#-----------Configuring nodes------------#
$ServerA shape hexagon
$ServerB shape hexagon
$Receiver shape square

#-----------Set End Times------------#

if {$fonte == "UDP"} {
    set endTime 0.81
}

if {$fonte == "TCP"} {
    set endTime 6
}

if {$fonte == "UDP" && $4_2 == "1"} {
    set endTime 3.2
}

if {$fonte == "TCP" && $cenario == "1" && $quebra == "0" && $4_2 == "0"} {
    set endTime 3.4
}

if {$fonte == "TCP" && $cenario == "1" && $quebra == "1" && $4_2 == "0"} {
    set endTime 3.7
}

#-----------Create CBR Traffic ------------#
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 3145728
$cbr0 set maxpkts_ 1

if {$fonte == "TCP"} {
    set tcp [new Agent/TCP]
    $tcp set fid_ 1
    $ns attach-agent $ServerA $tcp

    if {$janela == "0"} {
    } else {
        $tcp set window_ $janela
    }
    
    set sink [new Agent/TCPSink]
    $ns attach-agent $Receiver $sink
    $ns connect $tcp $sink
    $cbr0 attach-agent $tcp

    $tcp set class_ 1
    $ns color 1 Blue
}

if {$fonte == "UDP"} {
    
    set udp0 [new Agent/UDP]
    $ns attach-agent $ServerA $udp0
    
    set null0 [new Agent/Null]
    $ns attach-agent $Receiver $null0
    $ns connect $udp0 $null0
    $cbr0 attach-agent $udp0

    $udp0 set class_ 1
    $ns color 1 Blue
}

if {$cenario == "2"} {
    set udp1 [new Agent/UDP]
    $ns attach-agent $ServerB $udp1
    
    set cbr1 [new Application/Traffic/CBR]
    $cbr1 set rate_ 5Mb
    $cbr1 attach-agent $udp1
    
    set null1 [new Agent/Null]
    $ns attach-agent $Receiver $null1
    $ns connect $udp1 $null1
    $cbr1 attach-agent $udp1

    $udp1 set class_ 2
    $ns color 2 Red

    $ns at 0.5 "$cbr1 start"
    $ns at $endTime "$cbr1 stop"
}

$ns queue-limit $ServerA $R1 3146
if {$4_2 == "1" && $fonte == "UDP" && $cenario == "2"} {
    $ns queue-limit $R2 $Receiver 3517
}

if {$quebra == "1"} {
    
    #Quebra na ligação entre R1 e R2
    $ns rtmodel-at 0.6 down $R1 $R2
    $ns rtmodel-at 0.7 up $R1 $R2
}


#-----------Run-------------#
$ns at 0.5 "$cbr0 start"
$ns at $endTime "$cbr0 stop"
$ns at $endTime "fim"
$ns run

