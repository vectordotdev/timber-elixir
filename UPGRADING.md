# Upgrading

This documents outlines how to upgrade from major versions of Timber

## 1.x to 2.X

The 2.X introduces a number of enhancements and improvements. You can read more about the
new 2.X line [here]().

To upgrade, please follow these steps:

1. Delete `config/timber.exs`

2. Re-run the single command installer (`mix timber.install`). This commend, with your API-key,
   is located in the settings of your application. Here's a guide on locating your
   installation instructions:
   https://timber.io/docs/app/advanced/installation-instructions/