# Debugging Faults in Software Product Lines with Rule Induction Algorithms

Material of the experiments reported in the following paper submitted to the 
24TH ACM INTERNATIONAL SYSTEMS AND SOFTWARE PRODUCT LINE CONFERENCE (SPLC 2020):

*José Galindo, Ruben Heradio, David Fernandez-Amoros, and David Benavides*. 
**Debugging Faults in Software Product Lines with Rule Induction Algorithms.** 

## JHipster

[JHipster](https://www.jhipster.tech/) is a code generator for web applications 
with 45 selectable features that can produce a total of 26,256 valid configurations.

In:

*Axel Halin, Alexandre Nuttinck, Mathieu Acher, Xavier Devroey, Gilles Perrouin, Benoit Baudry*.
**Test them all, is it worth it? Assessing configuration sampling on the JHipster Web development 
stack**. *Empirical Software Engineering 24(2): 674-717 (2019).*

an exhaustive strategy is adopted to test the JHipster system, checking all its valid configurations.
The test cases, together with their resulting status, are [here](https://github.com/xdevroey/jhipster-dataset).

We have applied three  classical rule induction algorithms to explain the detected faults. 

Our experimental data is organized in the following directories:
* [original_data](https://github.com/rheradio/spl_fault_debugging/tree/master/jhipster/original_data) includes the CSV file with all tests gathered from [Halin et al.'s repository](https://github.com/xdevroey/jhipster-dataset).
* [script_code](https://github.com/rheradio/spl_fault_debugging/tree/master/jhipster/script_code) includes two scripts written in the R language:
  + [induce_rules.r](https://github.com/rheradio/spl_fault_debugging/blob/master/jhipster/script_code/induce_rules.r) processes the CSV in  [original_data](https://github.com/rheradio/spl_fault_debugging/tree/master/jhipster/original_data) and generates the explaining rules using three alternative algorithms: LEM2, CN2, and AQ. 
  + [crossvalidation.r](https://github.com/rheradio/spl_fault_debugging/blob/master/jhipster/script_code/crossvalidation.R) performs a 10-Fold cross-validation of the algorithms LEM2, CN2, and AQ. Also, the script generates a box-plot that summarizes the results.
  + [plot_rule_statistics](https://github.com/rheradio/spl_fault_debugging/blob/master/jhipster/script_code/plot_rule_statistics.R) generates the following plots to summarize the synthesized rules: (i) A histogram and a box-plot analyzing feature interactions, (ii) a cumulative plot relating the rules' coverage achieved with the interactions factor, and (iii) a histogram showing rules' coverage.
* [induced_rules](https://github.com/rheradio/spl_fault_debugging/tree/master/jhipster/induced_rules) includes the generated rules.
* [rule_statistics](https://github.com/rheradio/spl_fault_debugging/tree/master/jhipster/rule_statistics) includes the statistics generated with [crossvalidation.r](https://github.com/rheradio/spl_fault_debugging/blob/master/jhipster/script_code/crossvalidation.R) and [plot_rule_statistics](https://github.com/rheradio/spl_fault_debugging/blob/master/jhipster/script_code/plot_rule_statistics.R) .
