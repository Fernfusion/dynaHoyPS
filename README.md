# dynaHoyPS
## Problem
Hoymiles Inverters can be connected to using OpenDTU (https://github.com/tbnobody/OpenDTU) and a limit on the allowed output can be defined.

However, the output actually limits the input of the solar panels rather than the output of the inverter.

So, a lot of power is lost if e.g. the currently allowed output of 800 Watts is set and the panels are not capable of providing that much power because of the limitation.

As an example: A Hoymiles HMS-1600-4T with 4 * 435 Watts solar panels attached has to be limited to 800 Watts output in Germany.
Setting the limit to ~50% allows hitting that 800 Watts while each of the panels is limited to ~200 Watts output.
But if the power output of some panels decrease (e.g. they might face East as the other face South), still *all* panels suffer from the 200W limit, even though the South facing panels now could be allowed to have their input limit raised.

## Purpose
This PowerShell script connects to an OpenDTU which then connects to the Hoymiles inverter. The OpenDTU offers a REST API to query the combined power being produced and set power limits to reduce/increase the output.

## How-To

You need to configure some parameter:
  - `$localAddress`: set this to the IP address of your openDTU; example `192.168.178.188`
  - `$username`: set this to the username of the administrativ account of your openDTU; example `admin`
  - `$password`: set this to the password of the administrativ of your openDTU; example `openDTU42`
  - `$localAddress`: set this to the IP address of your openDTU; example `192.168.178.188`
  - `$powerLimit`: set this to the number of Watts you want the inverter to output at max
  - `$upperLimit`: set this to the upper limit the inverter should be set to; i.e. 100 means 100% of the max power output of your inverter; example `100`
  - `$lowerLimit`: set this to the minimum limit the inverter should be set to; i.e. 49 means 49% of the max power output of your inverter, which is just shy of 800 Watts for my HMS-1600-4T; example `49`
  - `$reactivityTime`: wait time in seconds after a power check with no action done; example `2`
