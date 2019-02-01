App = {
	web3Provider: null,
	contracts: {},
	account: '0x0',

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

			return App.render();
		});
	},

	render: function() {
		var electionInstance;
		var loader = $("#loader");
		var content = $("#content");

		loader.show();
		content.hide();

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

				var candidatesSelect = $('#candidatesSelect');
				candidatesSelect.empty();

				for (var i = 1; i <= playerCount; i++) {
					electionInstance.players(i)
						.then(function(player) {
							var name = player[0];
							var status = player[1];

							// Render candidate Result
							var candidateTemplate = "<tr><td>" + name + "</td><td>" + status + "</td></tr>"
							candidatesResults.append(candidateTemplate);

							// Render candidate ballot option
							var candidateOption = "<option value='" + 1 + "' >" + name + "</ option>"
							candidatesSelect.append(candidateOption);
						});
				}
				return electionInstance.voters(App.account);
			})
			.then(function(hasVoted) {
				// Do not allow a user to vote
				if (hasVoted) {
					$('form')
						.hide();
				}
				loader.hide();
				content.show();
			})
			.catch(function(error) {
				console.warn(error);
			});
	},

	castVote: function() {
		var candidateId = $('#candidatesSelect')
			.val();
		App.contracts.RockPaperScissors.deployed()
			.then(function(instance) {
				console.log(candidateId);
				return instance.vote(candidateId, { from: App.account });
			})
			.then(function(result) {
				// Wait for votes to update
				$("#content")
					.hide();
				$("#loader")
					.show();
			})
			.catch(function(err) {
				console.error(err);
			});
	},

	registerPlayer: function() {
		App.contracts.RockPaperScissors.deployed()
			.then(function(instance) {
				console.log("Calling function");
				return instance.registerPlayer({ from: App.account });
			})
			.then(function(result) {
				// Wait for votes to update
				console.log("Player Registered");
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
					console.log("event triggered", result.event);
          if (prevEvent) {
            //Skip prev event
            prevEvent = false;
          } else if (result.event == "StatusEvent") {
						App.render();
					} else if (result.event == "ErrorEvent") {
						alert(result.args.error);
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
