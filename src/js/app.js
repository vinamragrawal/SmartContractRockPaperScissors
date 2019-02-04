App = {
	web3Provider: null,
	contracts: {},
	account: '0x0',
	itemChoices: 0,

	init: function() {
		return App.initWeb3();
	},

	initWeb3: function() {
		if (typeof web3 !== 'undefined') {
			// If a web3 instance is already provided by Meta Mask.
			App.web3Provider = web3.currentProvider;
			web3 = new Web3(web3.currentProvider);
		} else {
			// Specify default instance if no web3 instance provided
			App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
			web3 = new Web3(App.web3Provider);
		}
		return App.initContract();
	},

	initContract: function() {
		$.getJSON("RockPaperScissors.json", function(election) {
			// Instantiate a new truffle contract from the artifact
			App.contracts.RockPaperScissors = TruffleContract(election);
			// Connect provider to interact with contract
			App.contracts.RockPaperScissors.setProvider(App.web3Provider);

			//Skip if any prev Event exist for this block,
			prevEvent = false;
			App.contracts.RockPaperScissors.deployed()
				.then(function(instance) {
					solidityEvent = instance.allEvents();

					solidityEvent.watch(function(err, result) {
						prevEvent = true;
					});
				});

			App.listenForEvents();

			lastRender = 0;
			return App.render();
		});
	},

	render: function() {
		if (Date.now() - lastRender < 200) {
			return;
		}
		lastRender = Date.now();

		var electionInstance;
		var loader = $("#loader");
		var content = $("#content");
    var registerButton = $("#registerButton");
    var choices = $("#choices");
    var revealButton = $("#revealButton");

		loader.show();
		content.hide();

		//Default show register button
		registerButton.show();
		choices.hide();
		revealButton.hide();

		// Load account data
		web3.eth.getCoinbase(function(err, account) {
			if (err === null) {
				App.account = account;
				$("#accountAddress")
					.html("Your Account: " + account);
			}
		});

		App.contracts.RockPaperScissors.deployed()
			.then(function(instance) {
				electionInstance = instance;
				return electionInstance.playerCount();
			})
			.then(function(playerCount) {
				var candidatesResults = $("#candidatesResults");
				candidatesResults.empty();

				for (var i = 1; i <= playerCount; i++) {
					electionInstance.players(i)
						.then(function(player) {
							var name = player[0];
							var status = player[1];
              var addr = player[2];
              var hasAttacked = player[3];
              var revealedId = player[4];

              if (player[2] == App.account){
                  //If table has current player bold it
                  name = "<strong>" + name + "</strong>";
                  status = "<strong>" + status + "</strong>";

                  //Manage UI components
                  if (revealedId != 0){
                      //Nothing to do
                      registerButton.hide();
                      choices.hide();
                      revealButton.hide();
                  } else if (hasAttacked == true) {
                      //Waiting to reveal
                      registerButton.hide();
                      choices.hide();
                      revealButton.show();
                  } else {
										  //Waiting to Choose
											registerButton.hide();
                      choices.show();
                      revealButton.hide();
									}
              }

              // Render candidate Result
							var candidateTemplate = "<tr><td>" + name + "</td><td>" + status + "</td></tr>";

							candidatesResults.append(candidateTemplate);
						});
				}
				loader.hide();
				content.show();
			})
			.catch(function(error) {
				console.warn(error);
			});
	},

	attack: function(itemId) {

		App.contracts.RockPaperScissors.deployed()
			.then(function(instance) {
				return instance.randomNumber();
			})
			.then(function(result) {
				var contractRandomNumber = Number(result);

				var randNum = Math.floor(Math.random() * Math.pow(10, 6));
				var choice = randNum * App.itemChoices + itemId;
        var sum = Number(contractRandomNumber) + Number(choice);
        var val = left_pad(sum.toString(16),64);
				var hash = web3.sha3(val, { encoding: 'hex' })

				if (localStorage.getItem(App.account) === null) {
					localStorage.setItem(App.account, choice);
				} else {
					alert('Error: Already chosen an item');
					return;
				}

				App.contracts.RockPaperScissors.deployed()
					.then(function(instance) {
						return instance.attack(hash, { from: App.account });
					})
					.then(function(result) {
						App.render();
					})
					.catch(function(err) {
						console.error(err);
					});
			})
			.catch(function(err) {
				console.error(err);
			});
	},

	registerPlayer: function() {
		var randNum = Math.floor(Math.random() * Math.pow(10, 10));
		App.contracts.RockPaperScissors.deployed()
			.then(function(instance) {
				return instance.registerPlayer(randNum, { from: App.account });
			})
			.then(function(result) {})
			.catch(function(err) {
				console.error(err);
			});
	},

	revealItem: function() {
		App.contracts.RockPaperScissors.deployed()
			.then(function(instance) {
				return instance.revealItem(parseInt(localStorage.getItem(App.account)), { from: App.account });
			})
			.then(function(result) {
				App.render();
			})
			.catch(function(err) {
				console.error(err);
			});
	},

	listenForEvents: function() {
		App.contracts.RockPaperScissors.deployed()
			.then(function(instance) {
				solidityEvent = instance.allEvents();

				solidityEvent.watch(function(err, result) {
					if (prevEvent) {
						//Skip prev event
						prevEvent = false;
					} else if (result.event == "StatusEvent") {
						App.render();
					} else if (result.event == "ErrorEvent") {
						alert(result.args.error);
					} else if (result.event == "WinnerEvent") {
						alert(result.args.msg);
            //Clear storage for next round
            localStorage.clear();
					}
				});
			});
	}
};

$(function() {
	$(window)
		.load(function() {
			App.init();
		});
});

function left_pad (str, max) {
  str = str.toString();
  return str.length < max ? left_pad("0" + str, max) : str;
}
