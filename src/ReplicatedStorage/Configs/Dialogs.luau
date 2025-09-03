local Dialogs = {}

Dialogs.Test = {
	Phrase = {
		{"Test phrase", 0};
	};
	Responses = {
		[1] = {
			Phrase = "Yes!";

			Type = "Action";
			Action = function(self)
				self._controllers.ClientMessagesSender:SendMessage("Default", "Test Dialog")
				self:EndDialog()
			end;
		};
		[2] = {
			Phrase = "No";
			Type = "EndDialog";
		};
		[3] = {
			Phrase = "May be";
			Type = "ContinueDialog";
			ContinuingDialog = "Test";
		}
	}
}

return Dialogs