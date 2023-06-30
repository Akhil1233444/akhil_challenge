# Enter your code here. Read input from STDIN. Print output to STDOUT
import re

def validate_cc_number(card_number):

    if re.search(r'(\d)\1{3}', card_number.replace('-', '').replace(' ', '')) or ' ' in card_number or re.search(r'(\d)\{5}', card_number):
        return False 
    
    if not re.search(r'^(4|5|6)[1-9]{3}-?[1-9]{4}-?[1-9]{4}-?[1-9]{4}$', card_number):
         return False

    return True

cc_number = int(input())

for _ in range(cc_number):
    card_number = input()

    if validate_cc_number(card_number):
        print("Valid")
    else:
        print("Invalid")
