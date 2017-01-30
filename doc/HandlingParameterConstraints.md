# TemPSS: Parameter Constraints

###Overview

TemPSS (Templates and Profiles for Scientific Software) displays the parameters for a Nektar++ solver in a tree structure that groups parameters according to their meaning and how they are related. While this helps a user to understand the required parameters and how they relate to the computation to be undertaken, there can be many constraints between parameters and these constraints are not necessarily between parameters in the same branch of a tree.

Since representing constraints or dependencies that cross branches/layers of a tree structure can be challenging, we simplify this by using an external XML constraint definition file that is used to set out details of constraints between pairs or groups of parameters in a flat structure. The constraint file for a solver is specified in the solver's template setup file and read when a template is loaded and displayed in the TemPSS user interface.

The approach of using a separate constraint definition file also offers the potential to undertake verification of profile descriptions that have been developed or modified outside of TemPSS.

In this document we describe the different types of constraints that are supported by TemPSS and how to define these contraints in XML within a constraint definition file. TemPSS will then use this file to present constraints in the user interface and use them to validate and guide users' parameter choices.

## Constraint types

This section describes the constraints currently supported by the constraint language detailed in the [Specifying Constraints](#specifying-constraints) section.

1. __Parameter pair constraint (choice)__: This type of constraint occurs when there are two parameters that both have drop-down lists of value choices and selecting a given value for one of the parameters (the source) restricts the choices that can be made for the other parameter (the target). *Note that this is a __two way__ constraint so selecting an option for the target should also restrict the available choices for the source.*

2. __Parameter pair constraint (text/choice)__: This constraint is similar to constraint type 1 except that one of the parameters provides a text input box rather than a choice drop down. In such constraints we class the text input value as the source and the choice input value as the target. A regular expression must be provided to define one or more source value strings and a corresponding set of valid target choice values. *Note that this is a __one way__ constraint, that is, selecting an option from the target value list will not suggest or constrain what can be entered as a source value but a previously selected target value will be marked as invalid if a source value is subsequently entered for which the target value is not valid.*

3. __Parameter pair constraint (text)__: *There is currently limited support for this type of parameter constraint in TemPSS.* This type of constraint may exist between two tree values with text input boxes to specify their values. At present we only support constraints between parameters that accept the entry of integer or double values. Constraints are specified using standard logic operators for specific source/target values or ranges of values. *Note that this is a __two way__ constraint so value restrictions can be specified for both the source and target parameters.*

4. __Multi-parameter constraint (choice)__: This type of constraint occurs between more than two parameters that all have choice input types providing a list of valid parameters. For each value of each parameter, where a constraint occurrs, the constraint defintion will describe all the valid options for each of the other parameters involved in the constraint relationship. *This is a __multi-way__ constraint and changing the value of any parameter involved in the constraint relationship should mark any other values involved as invalid if they are not compatible with one or more other selected values.*

5. __Multi-parameter constraint (choice/text and text)__: *Constraints between more than two parameters where one or more of these parameters is a text input parameter are not currently supported in TemPSS.*

6. __Individual parameter constraint__: This relates to any constraint on an individual parameter such as a value range restrictions specific invalid values or regular expressions describing valid or invalid text values.


## Specifying constraints

A constraints file for a template should have a `.xml` extension. The file is linked to the template through an option in the template properties file. Template property files are stored in the TemPSS source tree at `src/main/resources/Template`. The constraints file is specified using the constraints key. For example, a template that has its `component.id` set to `nektar-ins` would have a file named `INSConstraints.xml` specifying constraints for the template listed in the template properties file as:

```
nektar-ins.constraints=INSConstraints.xml
```

## The Constraint Definition File

Details of the constraint definition file, where it is located and how it is linked to a template.