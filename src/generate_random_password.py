#!/usr/bin/python3

import base64
import crypt
import argparse
import json
import random
import string
import sys


DEFAULT_CHARSET = string.ascii_letters + string.digits + string.punctuation
DEFAULT_LENGTH  = 16
MINIMUM_LENGTH  = 12

assert DEFAULT_LENGTH >= MINIMUM_LENGTH, \
    "Password default length is not >= the minimum length."

class RandomPassword:

    """
    Simple class for generating a random password, and returning that 
    along with a base64-encoded version and a SHA512-encrypted string 
    for use with `chpass`.
    """


    def __init__(self, charset=DEFAULT_CHARSET, length=DEFAULT_LENGTH):
        self.charset   = charset
        self.length    = length
        self.password  = {
            'plaintext': None,
            'encoded': None,
            'encrypted': None
        }
        self.generate()
        self.encode()
        self.encrypt()


    def generate(self):
        """
        Returrns a string of the specified length composed of randomly-
        chosen characters. The set of characters which form the corpus
        of the returned string can be specified at instantiation by
        passing a string to the charset= arg. The length can be specified 
        at instantiation by passing in the length= arg.
        """
        self.password['plaintext'] = "".join(
            random.choice(self.charset) for n in range(0, self.length))


    def encode(self):
        """
        Returns a Base64-encoded version of the plaintext as a 
        convenience. This has been used to avoid shell interpretation
        when used in shell scripts. (Ex. '$' and '!' chars have special
        meaning to many shells).
        """
        self.password['encoded'] = base64.b64encode(
                self.password['plaintext'].encode()).decode()


    def encrypt(self):
        """
        """
        self.password['encrypted'] = crypt.crypt(
                self.password['plaintext'], 
                crypt.mksalt(crypt.METHOD_SHA512))


    def to_json(self):
        """
        """
        print(json.dumps(self.password, sort_keys=True, indent=4))



def length_type(l):
    l = int(l)
    if l < MINIMUM_LENGTH:
        raise argparse.ArgumentTypeError(
            "The minimum length is {}".format(MINIMUM_LENGTH))
    return l


def main():
    parser = argparse.ArgumentParser(
        description='This is a description.')
    #parser.formatter_class = argparse.ArgumentDefaultsHelpFormatter
    parser.add_argument('--id', 
        help='Unique identifer for this run')
    parser.add_argument('-l', '--length', 
        type=length_type,
        default=DEFAULT_LENGTH,
        help='length of the generated plaintext')
    parser.add_argument('-s', '--charset',
        default=DEFAULT_CHARSET,
        help='string of characters to use when generating plaintext')

    args = parser.parse_args()

    RandomPassword(charset=args.charset, length=args.length).to_json()


if __name__ == "__main__":
    main()


