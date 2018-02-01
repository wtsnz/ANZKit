# ANZKit

This is based off of the ANZ GoMoney API v6.0

## About

I spent some time last year creating a watchOS app for a bank in NZ.

This has been implemented with RxSwift as I wanted a project to try out reactive programming.

Tests are extremely light.

## Changes from v5 -> v6

Seems that the entire API is based on public/private key crypto, nice! This is by far the best implementation of a banking API in NZ.

## Build Instructions

Open a terminal instance into the cloned directory

    carthage bootstrap --platform iOS
    cp ANZ/Secrets.swift.template ANZ/Secrets.swift

(The secrets file is to automagically fill in your account details, you do not have to put them in this file, it just needs to be there to build)

## Base URL

This is all accessible by anyone by simply proxying your device through something like Charles Proxy.

There are actually two base urls in v6. One is the preauth system, and one is the data service.

    https://digital.anz.co.nz/preauth/web/api/v1

and 

    https://secure.anz.co.nz/api/v6


...TBC