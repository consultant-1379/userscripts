#!/bin/bash

userName=qfatonu

/usr/bin/ssh -f $userName@atrcts15.athtem.eei.ericsson.se -L 2225:gerrit.ericsson.se:29418 -N
