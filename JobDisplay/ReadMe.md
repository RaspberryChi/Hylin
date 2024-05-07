# JobDisplay

Show status of select spells and abilities for current job/sub job


Settings:

To change how abilities or spells are displayed update the data/ability_data.xml file
all abilities should be in the file, spells will need to be added
	type: ability|spell|pet 	(controls how ability is looked up)
    flash: true|false 			(gives ability priority in sorting function and makes it flash when ready)
    weight: # 					(weight for sorting function, higher number gets higher priority, abilities sorted left to right then top to bottom)
    display: true|false			(controls ability visibility)


Commands:

//jd|jobdisplay help 					(show a list of available commands)

//jd|jobdisplay columns|cols|col [#] 	(set number of columns to display, accepts 1-20)

//jd|jobdisplay showall|all 			(show all available job abilities)

//jd|jobdisplay pos [x] [y]				(set text box position)

![jobdisplay](http://i.imgur.com/.jpg)