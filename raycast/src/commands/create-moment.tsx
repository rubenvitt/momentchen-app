/**
 * Create Moment Command
 * Allows users to quickly capture a new moment
 */

import { Action, ActionPanel, Form, showToast, Toast, useNavigation, popToRoot } from "@raycast/api";
import { useState, useEffect } from "react";
import { useCachedPromise } from "@raycast/utils";
import NotionAPIClient from "../api/notion";
import { momentToNotionProperties } from "../utils/notion-mapper";
import { MomentTypes } from "../types/moment";
import { invalidateMomentsCache } from "../utils/cache";

interface FormValues {
  title: string;
  type: string;
  timestamp: Date;
  categoryType: "none" | "project" | "lifeArea";
  categoryId?: string;
}

interface RelationOption {
  id: string;
  title: string;
}

export default function CreateMoment() {
  const { pop } = useNavigation();
  const [isLoading, setIsLoading] = useState(false);
  const [categoryType, setCategoryType] = useState<"none" | "project" | "lifeArea">("none");

  // Load projects and life areas
  const { data: projects = [], isLoading: projectsLoading } = useCachedPromise(
    async () => {
      const client = new NotionAPIClient();
      return await client.getRelationOptions("Projekt");
    },
    [],
    { execute: true }
  );

  const { data: lifeAreas = [], isLoading: lifeAreasLoading } = useCachedPromise(
    async () => {
      const client = new NotionAPIClient();
      return await client.getRelationOptions("Lebensbereich");
    },
    [],
    { execute: true }
  );

  async function handleSubmit(values: FormValues) {
    setIsLoading(true);

    try {
      const client = new NotionAPIClient();

      // Create base properties
      const properties = momentToNotionProperties({
        title: values.title,
        type: values.type,
        timestamp: values.timestamp,
      });

      // Add category relation if selected
      if (values.categoryType === "project" && values.categoryId) {
        properties["Projekt"] = {
          relation: [{ id: values.categoryId }],
        };
      } else if (values.categoryType === "lifeArea" && values.categoryId) {
        properties["Lebensbereich"] = {
          relation: [{ id: values.categoryId }],
        };
      }

      // Create the page
      await client.createPage({ properties });

      // Invalidate cache so the new moment appears immediately in search
      invalidateMomentsCache();

      await showToast({
        style: Toast.Style.Success,
        title: "Moment erstellt",
        message: values.title,
      });

      // Return to root (closes the form)
      await popToRoot();
    } catch (error) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Fehler beim Erstellen",
        message: error instanceof Error ? error.message : "Unbekannter Fehler",
      });
    } finally {
      setIsLoading(false);
    }
  }

  const isLoadingOptions = projectsLoading || lifeAreasLoading;

  return (
    <Form
      isLoading={isLoading || isLoadingOptions}
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Moment Erstellen" onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.TextArea
        id="title"
        title="Beschreibung"
        placeholder="Was ist passiert oder was hast du gedacht?"
        autoFocus
      />

      <Form.Dropdown id="type" title="Typ" defaultValue="learning">
        <Form.Dropdown.Item value="learning" title="Learning 📚" />
        <Form.Dropdown.Item value="improvement" title="Improvement 📈" />
        <Form.Dropdown.Item value="feeling" title="Feeling ❤️" />
        <Form.Dropdown.Item value="miss" title="Miss 😔" />
        <Form.Dropdown.Item value="Gedanke" title="Gedanke 💭" />
        <Form.Dropdown.Item value="Erlebnis" title="Erlebnis ✨" />
        <Form.Dropdown.Item value="Aktivität" title="Aktivität 🏃" />
        <Form.Dropdown.Item value="Idee" title="Idee 💡" />
      </Form.Dropdown>

      <Form.DatePicker
        id="timestamp"
        title="Zeitpunkt"
        defaultValue={new Date()}
        type={Form.DatePicker.Type.DateTime}
      />

      <Form.Separator />

      <Form.Dropdown
        id="categoryType"
        title="Kategorie"
        value={categoryType}
        onChange={(value) => setCategoryType(value as "none" | "project" | "lifeArea")}
      >
        <Form.Dropdown.Item value="none" title="Keine Kategorie" icon="➖" />
        <Form.Dropdown.Item value="project" title="Projekt" icon="📁" />
        <Form.Dropdown.Item value="lifeArea" title="Lebensbereich" icon="🌱" />
      </Form.Dropdown>

      {categoryType === "project" && (
        <Form.Dropdown id="categoryId" title="Projekt wählen" storeValue>
          {projects.length === 0 && <Form.Dropdown.Item value="" title="Keine Projekte verfügbar" />}
          {projects.map((project) => (
            <Form.Dropdown.Item key={project.id} value={project.id} title={project.title} />
          ))}
        </Form.Dropdown>
      )}

      {categoryType === "lifeArea" && (
        <Form.Dropdown id="categoryId" title="Lebensbereich wählen" storeValue>
          {lifeAreas.length === 0 && <Form.Dropdown.Item value="" title="Keine Lebensbereiche verfügbar" />}
          {lifeAreas.map((area) => (
            <Form.Dropdown.Item key={area.id} value={area.id} title={area.title} />
          ))}
        </Form.Dropdown>
      )}

      <Form.Description text="Favoriten-Status wird später während Reviews gesetzt" />
    </Form>
  );
}
