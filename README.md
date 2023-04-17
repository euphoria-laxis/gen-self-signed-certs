# Self signed certifcates generator command

This script generate self signed SSL certificates using algorythm RSA, ECDSA or
ED25519.

## Usage

### Arguments

* **-o** *(output)*: directory where certificates files will be generated.
* **-t** *(type)*: certificates type. Valid values : 
	* RSA
	* ECDSA
	* ED25519
* **-d** *(domain)*: domain that will use the certificates.
* **-e** *(email)*: contact email.
* **-C** *(country)*: organisation country.
* **S** *(state)*: organisation state.
* **O** *(organisation)*: organisation name.
* **U** *(unit)*: organisation unit.
* **L** *(locale)*: locale.
* **?** *(help)*: display help message.

### Example

The following command will generate certificates and signing keys for domain
**euphoria-laxis.com** with contact email **webmaster@euphoria-laxis.com** for
organisation EuphoriaLaxis, unit EuphoriaLaxis, located in France, region Île 
de France, using locale FR *(french)* using RSA algorythm and output
certificates to `./certs`.

````sh
self-signed_certs.sh -t RSA -o ./certs \
	-d euphoria-laxis.com -e webmaster@euphoria-laxis.com -C FR \
	-S IDF -O EuphoriaLaxis -U EuphoriaLaxis -L FR
````

## License

This project is under [MIT license](./LICENSE).