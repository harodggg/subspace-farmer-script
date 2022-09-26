#!/usr/bin/env python3
from substrateinterface import SubstrateInterface,Keypair
from json import dump
from sys import argv
from os.path import basename
from colorama import Fore,Back,Style
from time import localtime



all_address=[]
        
    

def generate_file_name():
    tl=localtime()
    return "(UTC+8)0"+str(tl.tm_mon)+"-"+str(tl.tm_mday)+'-'+str(tl.tm_hour)+':'+str(tl.tm_min)+":"+str(tl.tm_sec)+".json"


def generate_address(ss58_format):
    mnemonic = Keypair.generate_mnemonic()
    keypair = Keypair.create_from_mnemonic(mnemonic,ss58_format=ss58_format)
    return [mnemonic,keypair.ss58_address]

    
def main():
    print(Fore.BLUE)
    if len(argv) == 2 and float(argv[1]):
        print(Fore.GREEN)
        print("[".format(end=""))
        for i in range(0,int(argv[1])):
            keypair = generate_address(2254)
            all_address.append(
                {"seq":i,
                "keypair":keypair
                }
                )
            print("{},".format(keypair[1])) 
        print("]")
        with open(generate_file_name(), 'w') as f:
            dump(all_address,f,sort_keys=True, indent=4, separators=(',', ':'))
    else: 
        print("Usage: {} options (num)".format(basename(argv[0])))
    print (Style.RESET_ALL)



main()




