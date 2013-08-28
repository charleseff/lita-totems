# lita-totems

Totems handler for [Lita](https://github.com/jimmycuadra/lita)

## Installation

NOT YET WORKING, DON'T ATTEMPT TO USE YET

Add lita-totems to your Lita instance's Gemfile:

``` ruby
gem "lita-totems"
```

## Configuration

TODO: Describe any configuration attributes the plugin exposes.

## Usage

TODO: Describe the plugin's features and how to use them.

## License

[MIT](http://opensource.org/licenses/MIT)

## Todo:

* core routes:
	* Create a totem (set ACL?)
		* create
	* Destroy a totem
		* destroy, delete
	* join queue for totem
		* route: join, add, take, queue
	* yield a totem
		* route: yield, finish, leave, done, complete, remove
		* should also notify next person
		* should not require totem name if user only has one totem
			* if user has multiple totems but doesn't specify totem to yield, lita tells user which totems she has to yield (and provides commands)
	* kick someone from totem/queue
		* options: with our without username.  without username, kicks person holding the totem.  with username, kicks person from the queue (or the totemholder)
		* route: kick
		* example: kick totem <username>
		* notifies user that he/she's been kicked from queue
	* info (get all totem info, plus queues you're on as primary)
* extras:
    * totem groups
	