/* 
 * Copyright 2014 Sandia Corporation.
 * Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation, the U.S.
 * Government retains certain rights in this software.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * This software was written as part of an Inter-Agency Agreement between Sandia
 * National Laboratories and the US EPA NHSRC.
 */
package gov.sandia.seme.framework;

import java.util.ArrayList;
import java.util.HashMap;
import org.apache.log4j.Logger;

/**
 * @if doxyDev
 * @page devDescriptors Creating Descriptor Objects Programmatically
 * 
 * @endif
 */
/**
 * An encapsulation of a SeMe component's configuration. The component type,
 * implementation class, name, messaging tag, and a HashMap of options should
 * all be provided. There are also two arrays of strings, consumesTags
 * and producesTags, which provide additional message routing
 * information. These arrays should be populated during an initial pass through
 * the configuration information for a framework application. They then provide
 * easy access to the tags that a given object produces or consumes, which
 * tracks required inputs and outputs and aids in configuration, setup, and
 * initialization.
 *
 * @htmlonly
 * @author David Hart, dbhart
 * @endhtmlonly
 */
public class Descriptor {

  private static final Logger LOG = Logger.getLogger(Descriptor.class);
  String className;
  String componentType = null;
  ArrayList<String> consumesTags;
  String generatingClass = null;
  String name;
  HashMap options;
  ArrayList<String> producesTags;
  ArrayList<Descriptor> requiresComponents;
  String tag;
  ComponentType type;
  boolean used;

  /**
   * Create a new, blank Descriptor.
   */
  public Descriptor() {
    this.producesTags = new ArrayList();
    this.consumesTags = new ArrayList();
    this.requiresComponents = new ArrayList();
  }

  /**
   * Initialize new object with a <code>type</code> specified.
   *
   * @param type what type of object this describes
   */
  public Descriptor(String type) {
    this.type = ComponentType.valueOf(name);
    this.producesTags = new ArrayList();
    this.consumesTags = new ArrayList();
    this.requiresComponents = new ArrayList();
  }

  /**
   * Initialize new object with most of the necessary options.
   *
   * @param type what type of object this describes
   * @param name object name
   * @param asClass Java class to create this object with
   * @param config configuration options for this object
   */
  public Descriptor(String type, String name, String asClass, HashMap config) {
    this.producesTags = new ArrayList();
    this.consumesTags = new ArrayList();
    this.requiresComponents = new ArrayList();
    this.name = name;
    this.type = ComponentType.valueOf(type);
    this.options = config;
    this.className = asClass;
  }

  /**
   * Add a single tag to the list of consumables.
   *
   * @param tag messaging tag name to add
   */
  public void addToConsumesTags(String tag) {
    if (!this.consumesTags.contains(tag)) {
      this.consumesTags.add(tag);
    }
  }

  /**
   * Add a list of tags to the list of consumables.
   *
   * @param list messaging tags to add
   */
  public void addToConsumesTags(ArrayList<String> list) {
    for (String ltag : list) {
      if (!this.consumesTags.contains(ltag)) {
        this.consumesTags.add(ltag);
      }
    }
  }

  /**
   * Add a tag to the list of producesTags.
   *
   * @param tag tag to be added to the list
   */
  public void addToProducesTags(String tag) {
    if (!this.producesTags.contains(tag)) {
      this.producesTags.add(tag);
    }
  }

  /**
   * Add a list of tags to the list of producesTags.
   *
   * @param list tags to be added to the list
   */
  public void addToProducesTags(ArrayList<String> list) {
    for (String ltag : list) {
      if (!this.producesTags.contains(ltag)) {
        this.producesTags.add(ltag);
      }
    }
  }

  /**
   * Add a Descriptor to the list of required SubComponents
   *
   * @param obj descriptor to be added
   */
  public void addToRequiresComponents(Descriptor obj) {
    this.requiresComponents.add(obj);
  }

  /**
   * Add a list of descriptors to the list of required tags.
   * 
   * @param list descriptors to be added to the list
   */
  public void addToRequiresComponents(ArrayList<Descriptor> list) {
    for (Descriptor desc : list) {
      if (!this.requiresComponents.contains(desc)) {
        this.requiresComponents.add(desc);
      }
    }
  }
  
  /**
   * Clear the requiresComponents list.
   */
  public void clearRequiresComponents() {
    this.requiresComponents.clear();
  }

  /**
   * Get the value of className (for the described object)
   *
   * @return value of className
   */
  public String getClassName() {
    return className;
  }

  /**
   * Set the value of className (for the described object)
   *
   * @param className the new value of className
   */
  public void setClassName(String className) {
    this.className = className;
  }

  /**
   * Get the value of componentType
   *
   * @return the value of componentType
   */
  public String getComponentType() {
    return componentType;
  }

  /**
   * Set the value of componentType
   *
   * @param componentType new value of componentType
   */
  public void setComponentType(String componentType) {
    this.componentType = componentType;
  }

  /**
   * Get the list of tags this object consumesTags.
   *
   * @return list of consumed tags
   */
  public ArrayList<String> getConsumesTags() {
    return consumesTags;
  }

  /**
   * Set the list of consumed object tags.
   *
   * @param consumesTags
   */
  public void setConsumesTags(ArrayList<String> consumesTags) {
    this.consumesTags = consumesTags;
  }

  /**
   * Get the value of generatingClass
   *
   * @return the value of generatingClass
   */
  public String getGeneratingClass() {
    return generatingClass;
  }

  /**
   * Set the value of generatingClass
   *
   * @param generatingClass new value of generatingClass
   */
  public void setGeneratingClass(String generatingClass) {
    this.generatingClass = generatingClass;
  }

  /**
   * Gets the name of the described CMEF component object.
   *
   * @return name the name of the object
   */
  public String getName() {
    return name;
  }

  /**
   * Sets the name of the described CMEF component object.
   *
   * @param name the new value of name
   */
  public void setName(String name) {
    this.name = name;
  }

  /**
   * Get the configuration options.
   *
   * @return configuration details
   */
  public HashMap getOptions() {
    return options;
  }

  /**
   * Set the configuration options.
   *
   * @param options configuration details
   */
  public void setOptions(HashMap options) {
    this.options = options;
  }

  /**
   * Get the list of producesTags
   *
   * @return the value of producesTags
   */
  public ArrayList<String> getProducesTags() {
    return producesTags;
  }

  /**
   * Set the list of producesTags.
   *
   * @param producesTags the new list of producesTags
   */
  public void setProducesTags(ArrayList<String> producesTags) {
    this.producesTags = producesTags;
  }

  /**
   * Get the objects required to make this object work.
   *
   * @return list of required objects
   */
  public ArrayList<Descriptor> getRequiresComponents() {
    return requiresComponents;
  }

  /**
   * Set the objects required to make this object work
   *
   * @param requires new list of required objects
   */
  public void setRequiresComponents(ArrayList<Descriptor> requires) {
    this.requiresComponents = requires;
  }

  /**
   * Get the routing tag of this object.
   *
   * @return tag name
   */
  public String getTag() {
    return tag;
  }

  /**
   * Set the routing tag of this object.
   *
   * @param tag messaging tag of this object
   */
  public void setTag(String tag) {
    this.tag = tag;
  }

  /**
   * Get the component type.
   *
   * @return the type of the CMEF component described
   */
  public ComponentType getType() {
    return type;
  }

  /**
   * Set the component type.
   *
   * @param type component described
   */
  public void setType(String type) {
    this.type = ComponentType.valueOf(type);
  }

  /**
   * Set the component type.
   *
   * @param type component described
   */
  public void setType(ComponentType type) {
    this.type = type;
  }

  /**
   * Get the used status.
   *
   * @return usage status
   */
  public boolean isUsed() {
    return used;
  }

  /**
   * Set the value of used
   *
   * @param used the new value of used
   */
  public void setUsed(boolean used) {
    this.used = used;
  }

  /**
   * Remove a single tag from the list of consumesTags.
   *
   * @param tag tag name to remove
   */
  public void removeFromConsumesTags(String tag) {
    if (this.consumesTags.contains(tag)) {
      this.consumesTags.remove(tag);
    }
  }

  /**
   * Remove a single tag from the list of producesTags
   *
   * @param tag tag name to remove
   */
  public void removeFromProducesTags(String tag) {
    if (this.producesTags.contains(tag)) {
      this.producesTags.remove(tag);
    }
  }

  /**
   * Remove a list of values from the producesTags list
   *
   * @param list values to be removed from producesTags
   */
  public void removeFromProducesTags(ArrayList<String> list) {
    for (String ltag : list) {
      if (!this.producesTags.contains(ltag)) {
        this.producesTags.remove(ltag);
      }
    }
  }
}
