---
title: "Lottery on Ethereum Blockchain from A to Z"
date: 2021-05-26T18:42:00+02:00
summary: "We will explore _Ethereum_ smart contracts to create lottery
          without frauds where you can win real money."
---

## The problem
There are many sites where you can gamble, obviously.  However, when you
sent premium SMS or make a bet you have no idea if there is a malicious
actor who plays against your odds.  Perhaps only friends of the owner
can win, and you were not informed and wasted your hard-earned money.
There is no way to enforce honestly on those kinds of sites or
applications.

## Solution

This problem could not be solved until creation of a _blockchain_ and
_smart contracts_.  In short, _blockchain_ is a read-only, publicly visible
database.  Any additions or modifications has to be approved by majority
of a network which for many cryptocurrencies is close to impossible.
Therefore, once money were transfer, there is no way to revoke this
operation, even if they were stolen.  _Smart contract_ is a form of a
program that uses properties of _blockchain_.  It is immutable and
publicly visible.

What does it mean for our fair lottery?  It means, once the lottery was
created no changes in logic are possible and anyone can audit code
before betting.  If the contract is done right there is no way the owner
or anyone could exploit, change logic or steal the money from it.  Even
if you do not know how to program, someone else could review lottery
logic for you to make sure it is honest and safe.


## Writing smart contract
Now let us create an honest lottery where everyone has the same chance
to win and no one can alter the logic behind winning.  Yes, we are going
to write some code.  Also, I assume you have some basic understanding of
coding and cryptocurrencies.

My lottery will work as follows.
  * Player send money to smart contract lottery address.
  * If the player is lucky there is 1% chance to win the whole stake.
  * If player is unlucky money stays at the lottery and other players
    can win them by sending money to smart contract lottery.

Of course this just an example.  In the real world a lottery would be a
bit more sophisticated.  For instance, everyone should send the same
amount of money, but I want to keep this example to a bare minimum.
Also, you are free to modify this example and build an application around
this if you want to.

### Prerequisites
  * node
  * npm
  * MetaMask
  * Ganacache


### Initialization
First, lets initialize development environment for our first smart
contract:
```
npx truffle init
```

This would create a couple of directories and files and will give us a
quick start.


### Writing contract itself
Let us create a new file named **Lottery.sol**.

First line contains a comment with license, we will use GPLv2.
```solidity.
// SPDX-License-Identifier: GPL-2.0-or-later
```

Next we specify language version.  At the time of writing this post,
this is the latest.
```solidity
pragma solidity ^0.8.4;
```

Boring things done.  Now let us see how actual contract can look like.

Keyword **contract** is a bit like **class** in OOP languages.  In order to
create it we use _contract_ followed by its name.
```solidity
contract Lottery {
}
```

_Smart contract_ has its own _Ethereum_ address where you can send
money.  When you do that, a special function **receive** with
**payable** modifier is executed.  Let us see how that could look like
in our lottery.
```solidity
receive() external payable {
  require(msg.value > 0 ether, "You cannot send 0 eth");
  if (isLucky()) {
    payable(msg.sender).transfer(address(this).balance);
  }
}
```
In first line, we require players to put some actual money.  Then we
check if was lucky and if yes we send all the money from _smart
contract_ balance that were accumulated till now.

How to implement **isLucky** function.  This could be a bit tricky,
because every person in mining pool should receive the same pseudo
random number while keeping it unpredictable.

We will feed our hash function with, timestamp, difficulty and player
details.  Those things will always be the same for every miner, while
being a bit hard to guess.
```solidity
function isLucky() private view returns (bool ok) {
  // not sure if random enough
  uint256 random =
    uint256(
        keccak256(
          abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender
            )
          )
        );
  return random % 100 < 1;
}
```
We are using here two new modifiers **private** and **view**.  Former
means function is visible only in current contract, just like in regular
OOP, while latter means that function does not modify the state of our
contract.

To ease debugging a bit, we can emit an event from our **receive**
function winning branch and this will be saved in _blockchain_.
```solidity
event Payout(address indexed _from, uint256 indexed _balance);
...
if (isLucky()) {
...
  emit Payout(msg.sender, address(this).balance);
}
```

Last thing, we can set ourselves as owner of this _smart contract_.
Later we could add some functions that could be executed only by us
(optional).
```solidity
address public owner;

constructor() {
    owner = msg.sender;
}
```
When we deploy _smart contract_, constructor is executed only once, and it
will set owner address to a person who deployed it.


### Migration
_Truffle_ supports migrations of contracts which is similar to
versioning.  We need to create file **migrations/2_initial_lottery.js**
and put this:
```js
const Lottery = artifacts.require("Lottery");

module.exports = function (deployer) {
  deployer.deploy(Lottery);
};
```

### Deploying
We want to test our work.  First let us fire up _Ganacache_.  This will
create a test _blockchain_ for us.  Also, we need _MetaMask_ to connect
to our test blockchain to send some money to our newly deployed smart
contract.

Go to: **Settings** -> **Workspace** -> **Add project**, select **trufle-config.js**
and confirm with **Save and Restart**.

When you go to the contracts page you should see your lottery.
{{< figure src="ganache_contracts_1.png"
           link="ganache_contracts_1.png"
           title="Ganache contracts page"
>}}

The reason it says _not deployed_ is that we did not deploy yet.  Let's
fix that now.

```
npx truffle migrate
```

It would spit out some interesting things like how much it costs to
deploy your lottery to blockchain.

Now your _Ganache_ should look like this:
{{< figure src="ganache_contracts_deployed.png"
           link="ganache_contracts_deployed.png"
           title="Ganache contracts page after successfull deployment"
>}}

If you want to redeploy, because you made some changes or something, do:
```
npx truffle migrate --reset --compile-all
```


### Running
At this point we will be sending money from _MetaMask_ to our smart
contract address in order to execute lottery on our test network.

Install _MetaMask_ as a browser extension.  Go through some initial
steps and then click **Ethereum Mainnet** and then **custom RPC**.  Fill
out inputs as below.

{{< figure src="metamask_new_network.png"
           link="metamask_new_network.png"
           title="1337 because it is so leet" >}}

Take one of the _Ganache_ pre-created Accounts and copy the private key.
Now go to _MetaMask_ and click your avatar, then **Import account** and
paste private key you just copied.  You should see your balance now.

{{< figure src="metamask_balance.png"
           link="metamask_balance.png"
           title="Well that is a hell of out money" >}}

Go to _Ganacache_ again.  This time open _Contracts_ and copy address of
your lottery and send money to this address via _MetaMask_.  You need to
put some higher gas limit, because default 21000 is not enough.  50000
should do the trick.


{{< figure src="ganacache_contracts_executed.png"
           link="ganacache_contracts_executed.png"
           title="Tried two times, but no luck ;(" >}}


You can tweak the algorithm to allow 50% chance of winning.  That way
instead of making hundreds of transactions you can be lucky with just
two.  All you got to do is, change this line from
```solidity
return random % 100 < 1;
```

to
```solidity
return random % 100 < 51;
```

and execute this.
```
npx truffle migrate --reset --compile-all
```

Be aware that lottery contract address is different now.


{{< figure src="ganache_contracts_executed_lucky.png"
           link="ganache_contracts_executed_lucky.png"
           title="Now that chances are 50/50, I got payout the second time" >}}


## Conclusion
You see that it is fairly easy to implement honest lottery.  Of course
above example is not production ready, but it serves a good example of
what could be achieved.  It needs some more work, but I wanted to
introduce some basic concepts of _smart contracts_.  I also wrote some
tests that are available on my GitHub.  Did not want to get into details
this time.  This post is already pretty lengthy.

You can find whole project at:
https://github.com/dolohow/eth-lottery
