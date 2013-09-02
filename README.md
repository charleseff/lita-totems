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
	C Create a totem (set ACL?)
		* create
	C Destroy a totem
		* destroy, delete
	C add queue for totem
		* route: add, join, take, queue
	* yield a totem
		C route: yield, finish, leave, done, complete, remove
		* should also notify next person
		C should not require totem name if user only has one totem
			C if user has multiple totems but doesn't specify totem to yield, lita tells user which totems she has to yield (and provides commands)
		* should alert people in queue that they are closer in the queue
	* kick someone from totem/queue
		* route: kick
		* example: kick totem
		* notifies user that he/she's been kicked from queue
		* should alert people in queue that they are closer in the queue
	* info (get all totem info, plus queues you're on as primary)
	    * route : info, list
	    * route: just "totems" or "totems info"
	    * if passed a totem name, gets that totem's
* extras:
    * totem groups
	