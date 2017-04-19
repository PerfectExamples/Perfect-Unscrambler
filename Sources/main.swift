//
//  main.swift
//  Perfect Unscrambler
//
//  Created by Rockford Wei on 4/17/17.
//	Copyright (C) 2017 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2017 - 2018 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer

/// any valid word list file given each word per line.
let dictionaryURL = "https://raw.githubusercontent.com/dwyl/english-words/master/words.txt"

/// cdn of jQuery
let jqueryURL = "https://code.jquery.com/jquery-1.12.4.min.js"

/// github source of Reative-Extensions javascript
let reactiveURL = "https://raw.githubusercontent.com/Reactive-Extensions/RxJS/master/dist/rx.lite.compat.min.js"

/// server port to start with
let port = 8888

/// word groups
let words = WordGroups(dictionaryURL)

/// validate the input string
func sanitizedInput(_ name: String, _ req: HTTPRequest, _ size: Int = 32) -> String {
  let raw = req.param(name: name) ?? ""
  var buf = Array(raw.lowercased().utf8.filter { $0 > 96 && $0 < 123 }.prefix(size))
  buf.append(0)
  return String(cString: buf)
}//end validInput

/// api handler: will return a json solution for the puzzle
func apiHandler(data: [String:Any]) throws -> RequestHandler {
	return {
		request, response in
    let input = sanitizedInput("inp", request)
    let list = words.solve(scramble: input)
    do {
      let json = try list.jsonEncodedString()
      response.appendBody(string: json)
    }catch {
      response.appendBody(string: "[\"Error\"]")
    }//end do

    response.completed()
  }//end return
}//end handler

// default home page for jQuery+Reactive-Extension demo
let homePageWithReativeExtensionJS = "<html><head><title>Unscrambler</title>\n" +
  "<script src='\(reactiveURL)'></script>\n" +
  "<script src='\(jqueryURL)'></script><script>\n" +
  "(function (global, $, Rx) { \n" +
  "function search (term) { return $.ajax({ url: 'api', dataType: 'json', data: { inp: term } }).promise(); } \n" +
  "function main() { \n" +
  "var $input = $('#textInput'), $results = $('#results'); \n" +
  "var keyup = Rx.Observable.fromEvent($input, 'keyup').map(function (e) { return e.target.value; }) \n" +
  ".filter(function (text) { return text.length > 2; }).debounce(200).distinctUntilChanged(); \n" +
  "keyup.flatMapLatest(search).subscribe(function (data) { $results.empty() \n" +
  ".append ($.map(data, function (v) { return $('<li>').text(v); })); });} $(main); } (window, jQuery, Rx));" +
  "</script></head><body><H1>Perfect Unscrambler</H1>\n" +
  "<p><input type=text id=textInput placeholder='Enter Query...'></p><ul id=results></ul></body></html>"

/// page handler: will print a input form with the solution list below
func handler(data: [String:Any]) throws -> RequestHandler {
  return {
    request, response in
    response.setHeader(.contentType, value: "text/html")
    response.appendBody(string: homePageWithReativeExtensionJS)
    response.completed()
  }//end return
}//end handler

let confData = [
	"servers": [
		[
			"name":"localhost",
			"port":port,
			"routes":[
				["method":"get", "uri":"/", "handler":handler],
        ["method":"get", "uri":"/api", "handler":apiHandler]
			]
		]
	]
]

do {
	// Launch the servers based on the configuration data.
	try HTTPServer.launch(configurationData: confData)
} catch {
	fatalError("\(error)") // fatal error launching one of the servers
}
