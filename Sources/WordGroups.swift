//
//  WordGroups.swift
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
import PerfectCURL

/// load the dictionary into groups categorized by indices.
/// each group indicates all possible solution to a certain puzzle.
/// you can imagine that there are thousands of bags, each bag with a unique tag
/// and each bag contains one or more words with the same tag
public class WordGroups {

  /// Create a special key signature of the input word, for indexing purposes
  /// - parameters:
  ///   - word: the word to input
  /// - returns:
  ///   The function will convert the whole word into an alphabetic frequency table,
  ///   i.e., calculate the total occurrence of each letter in order and ignore those
  ///   letters that not present. For example, signature of word `boom` is `b1m1o2`
  func signature(word: String) -> String {

    // prepare an empty frequency table
    var table:[UInt8: Int] = [:]

    // get the lowercased string
    word.lowercased().utf8

      // remove all non-alphabetic characters, numbers and symbols
      .filter {$0 > 96 && $0 < 123}

      // build the frequency table
      .forEach { char in

        // get the current frequency of the objective character
        let f = table[char] ?? 0

        // increase one for the current
        table[char] = f + 1

      }//next

    return table.keys

      // must sort
      .sorted()

      // map it to strings like `a1`
      .map { key -> String in

        let buffer:[UInt8] = [key, 0]
        return String(cString: buffer) + String(describing: table[key] ?? 0)
      }

      // finally, join all key-frequency pair
      .joined()
  }//end signature

  internal var groups:[String:[String]] = [:]

  /// constructor
  /// - parameters:
  ///   - path: url to the dictionary file, note that the dictionary must be a text file without any null line break; each word shall not contain any non-alphabetic symbols or numbers
  public init (_ url: String) {

    print("[BOOT] download dictionary from \(url) ...")
    let curl = CURL(url: url)
    let r = curl.performFullySync()
    curl.close()

    guard r.resultCode == 0, r.bodyBytes.count > 0 else {
      fatalError("dictionary file is missing.")
    }//end file

    var total = 0
    r.bodyBytes.split(separator: 10).forEach {

        var s = Array($0)

        s.append(0)

        let word = String(cString: s)

        // calculate the signature
        let sig = signature(word: word)

        var list = groups[sig] ?? []

        list.append(word)

        groups[sig] = list

        total += 1
    }//next

    guard groups.count > 0 else {
      fatalError("dictionary file is empty.")
    }//end guard

    print("[BOOT] \(total) words are loaded into \(groups.count) groups.")

  }//end init

  /// solve a scramble
  /// - parameters:
  ///   - scramble: a scrambled word to solve
  ///   - limit: result set size control, default is 100; set 0 to return all
  public func solve(scramble: String, limit: UInt = 100) -> [String] {

    // calculate the key
    let key = signature(word: scramble)

    // retrieve the group from groups
    let group = groups[key] ?? []

    // return the result set excluding the puzzle itself with expected limitation
    return Array(group.prefix(Int(limit))).filter { $0 != scramble }
  }//end solve
}//end class
