# Timber Specification Adherence

Audits adherence to the [Timber library specification](timber_library_specification).

* Version: 3.0.0-alpha.3
* Last checked: 2018-10-16
* Checked by: David Antaramian

## Caveats

### Styling

The official `mix format` tool is used for formatting code. All other styling
should follow the `mix credo` guidelines which are controlled by `.credo.exs`.

### Documentation Coverage

Documentation coverage is determined using the `mix inch` tool which reports on
documentation coverage and quality.

## v1.0.0 - Basic Logging

|     Sec | Requirement                                                       |     |
|--------:|:------------------------------------------------------------------|:----|
|  **2.** | **Library, Code, and Language Convention**                        |     |
|     2.1 | Library is named `timber`                                         | [x] |
|     2.2 | Follows recommended language conventions                          | [x] |
|     2.3 | Implements an official styling standard                           | [x] |
|     2.4 | All public classes and/or modules are documented properly         | [ ] |
|     2.4 | All public methods are documented properly                        | [ ] |
|     2.4 | Method arguments are documented, including options                | [ ] |
|     2.4 | Examples are provided in documentation where relevant             | [ ] |
|     2.5 | Is semantically versioned                                         | [x] |
|     2.6 | Includes a properly formatted CHANGELOG                           | [x] |
|     2.7 | Has been made available on the proper package manager             | [x] |
|  **3.** | **Logging Pipeline**                                              |     |
|     3.1 | Properly integrates within the context of the language            | [x] |
|     3.1 | Provides separate libraries if integrating with 3rd party loggers | N/A |
|     3.1 | Can be easily swapped into existing applications                  | [x] |
|   3.2.1 | Exposes leveled methods (info, warn, etc)                         | N/A |
|   3.2.2 | Accepts generic string log messages                               | [x] |
|   3.3.2 | Can write logs to any IO device                                   | N/A |
|   3.3.3 | Provides a generic HTTP writer that transmits logs                | [x] |
| 3.3.3.1 | Sends logs in batches to the Timber service                       | [x] |
| 3.3.3.1 | The maxmimum batch flush size default is 1000                     | [x] |
| 3.3.3.1 | The maxmimum batch flush size is configurable                     | [x] |
| 3.3.3.1 | The maxmimum batch flush age default is 1 second                  | [x] |
| 3.3.3.1 | The maxmimum batch flush age is configurable                      | [x] |
| 3.3.3.1 | Log lines can be buffered after a flush starts                    | [x] |
| 3.3.3.1 | Flush errors do not affect the stability of the system            | [x] |
| 3.3.3.1 | Flush errors do not pause or stop the process in any way          | [x] |
| 3.3.3.1 | Request that results in 5XX responses are retried up to 3 times   | [ ] |
| 3.3.3.1 | Retries utilize an exponential backoff with jitter                | [ ] |
| 3.3.3.1 | Will recover after a sustained Timber service outage              | [x] |
| 3.3.3.2 | `Authorization` header is properly set                            | [x] |
| 3.3.3.3 | Payload is `UTF-8` encoded                                        | [x] |
| 3.3.3.4 | Payload uses a supported content type                             | [x] |
| 3.3.3.4 | The `Content-Type` header is properly set                         | [x] |
| 3.3.3.5 | The `User-Agent` header is properly set                           | [x] |

## v1.1.0 - Structured Logging

|     Sec | Requirement                                                                |     |
|--------:|:---------------------------------------------------------------------------|:---:|
|   **3** | **Logging Pipeline**                                                       |     |
|     3.1 | Additionally integrates with popular logging libraries                     | [x] |
|   3.2.3 | Accepts structured data as the message                                     | N/A |
|   3.2.4 | Accepts supplemental structured data                                       | [x] |
|   3.3.1 | Defines a log event data structure                                         | [x] |
| 3.3.1.1 | The JSON encoded log event properly adopts a versioned Timber event schema | [x] |
| 3.3.1.2 | Normalizes strings into Timber events                                      | [x] |
| 3.3.1.3 | Normalizes structured data into Timber events                              | [x] |
|   3.3.2 | Provides an IO device formatter that preserves structured data             | [x] |
|   3.3.2 | IO device formatter uses the proper `@metadata` delimiter                  | [x] |
|   3.3.2 | New line characters within the metadata are escaped                        | [x] |
|   3.3.2 | Formats logs before being sent to the IO device                            | [x] |

## v1.2.0 - Events

|     Sec | Requirement                                                      |     |
|--------:|:-----------------------------------------------------------------|:---:|
|   **3** | **Logging Pipeline**                                             |     |
|   3.2.5 | Accepts events as structured data                                | [x] |
| 3.3.1.3 | Normalizes Timber official events                                | [x] |
| 3.3.1.4 | Normalizes custom events                                         | [x] |
|   **4** | **Events**                                                       |     |
|     4.1 | Defines a base event data structure                              | [x] |
|     4.2 | Defines events for all Timber official events                    | [x] |
|     4.3 | Allows users to define custom events by extending the base event | [x] |

## v1.3.0 - Context

|     Sec | Requirement                                             |     |
|--------:|:--------------------------------------------------------|:---:|
|   **3** | **Logging Pipeline**                                    |     |
| 3.3.1.4 | Injects context into the final log event                | [x] |
|   **5** | **Context**                                             |     |
|     5.4 | Context data structure is a map or hash like structure  | [x] |
|     5.5 | Context can be JSON encoded                             | [x] |
|     5.6 | Adding context performs a shallow merge                 | [x] |
|     5.7 | Context can be removed on a key basis                   | [ ] |
|     5.8 | Context can be added and removed within a lexical scope | N/A |
|   5.9.1 | Runtime context is captured by default (if possible)    | [x] |
|   5.9.2 | Host context is captured by default                     | [x] |
|   5.9.3 | EC2 context is captured by default                      | [ ] |
|   5.9.4 | Heroku context is captured by default                   | [ ] |

[timber_library_specification]: https://github.com/timberio/library-specification
