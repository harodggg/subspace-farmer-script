#!/usr/bin/env python3
from substrateinterface import SubstrateInterface,Keypair
from colorama import Fore,Back,Style
from json import load
from sys import argv
from os.path import basename

substrate = SubstrateInterface(
    url="wss://eu-0.gemini-2a.subspace.network/ws",
    ss58_format=2254,
)

all_num = 0
def query_balance(subsrate,address):
    result = substrate.query(
        module='System',
        storage_function='Account',
        params=[address]
    )
    balance=format((result['data']['free'].value /  10 ** substrate.token_decimals),'.4f')
    all_num = all_num + (result['data']['free'].value /  10 ** substrate.token_decimals)
    print(Fore.BLUE+"[address: {},balance: {}-{}]".format(address,balance,substrate.token_symbol))

#address='st7mBWaPvtszhXdjfkVTXjDMFJDcmc8gvZA6gmUVeToPNnGuq'
#query_balance(substrate,address)
#print (Style.RESET_ALL)


def main():
    print(Fore.GREEN)
    if len(argv) == 2:
        with open(argv[1],'r') as f:
            all_address = load(f)['address']
            for address in all_address:
                query_balance(substrate,address)
    print(all_num)
    else:
        print("Usage: {} filename".format(basename(argv[0])))
    print (Style.RESET_ALL)

main()