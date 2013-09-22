now = new Date()
items = {}
currentBranch = "master"
builds = $("#builds")
repo = "https://github.com/mileswu/dokibox/commit/"
$.get "https://s3.amazonaws.com/dokibox-builds/", (data) ->
	contents = $(data).find("Contents")
	for c in [contents.length-1..0] by -1
		content = $(contents[c])
		if content.find("Key").text()[-7..-1] is ".tar.gz"
			item = parseContents content
			items[item.file.branch] = {} unless items[item.file.branch]
			items[item.file.branch][item.file.commit] = item
	for commit, item of items[currentBranch]
			builds.append """
				<li class="branch-#{item.file.branch} entry">
						<div class="size">#{item.size}</div>
						<a href="#{repo}#{item.file.commit}">
							<div class="commit">
								<img src="github-32.png">
							</div>
						</a>
						<a href="https://s3.amazonaws.com/dokibox-builds/#{item.file.full}">
							<div class="download">
								<img src="download-32.png">
							</div>
						</a>
				</li>
				"""

parseContents = (contents) ->
	item = {
		file: parseFilename contents.find("Key").text()
		date: humanizeDate new Date contents.find("LastModified").text()
		hash: contents.find("ETag").text()[1...-1].split('-')[0]
		size: humanizeSize contents.find("Size").text()
	}

parseFilename = (fullFileName) ->
	file = {
		full: fullFileName
	}
	# horrible monstrosities.
	[file.branch, file.commit] = fullFileName.match(/.+\/(.+?).tar.gz/)[1].match(/(.+)-(.+?$)/)[1..2]
	file

humanizeSize = (size) ->
	post = [' B', ' KiB', ' MiB', ' GiB', ' TiB', ' PiB', ' EiB', ' ZiB', ' YiB']
	dum = size
	count = 0
	while Math.floor dum # 0 == false
		dum /= 1024
		count++
	Math.round(size/(Math.pow(1024,(count-1)))*100)/100 + post[count-1]

humanizeDate = (date) ->
	pluralize = (quantity) -> if quantity is 1 then '' else 's'
	theDate = {
		alt: "on #{niceFormatDate date}"
	}
	diff = Math.round (now - date)/1000
	if diff < 60 # less than one minute
		theDate.text = "less than a minute ago."
		return theDate

	diff = Math.round diff/60
	if diff < 60 # less than one hour
		theDate.text = "#{diff} minute#{pluralize diff} ago."
		return theDate

	minutes = diff % 60
	diff = Math.round diff/60
	if diff < 24 # less than one day
		m = if minutes > 0 then ", #{minutes} minute#{pluralize minutes}" else ""
		theDate.text = "#{diff} hour#{pluralize diff}#{m} ago."
		return theDate

	hours = diff % 24
	diff = Math.round diff/24
	if diff < 7 # less than a week
		h = if hours > 0 then ", #{hours} hour#{pluralize hours}" else ""
		theDate.text = "#{diff} day#{pluralize diff}#{h} ago."
		return theDate

	weeks = Math.round diff/7
	days = diff % 7
	if weeks < 5
		d = if days > 0 then ", #{days} day#{pluralize days}" else ""
		theDate.text = "#{weeks} week#{pluralize weeks}#{d} ago."
		return theDate
	else
		theDate.text = theDate.alt
		return theDate

niceFormatDate = (date) ->
	pad = (n) -> return  if n < 10 then "0"+n else n
	return "#{date.getFullYear()}-#{pad date.getMonth() + 1}-#{pad date.getDate()} at #{pad date.getHours()}:#{pad date.getMinutes()}"
